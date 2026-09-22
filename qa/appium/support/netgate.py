"""네트워크 열화를 만들었다 푸는 TCP 프록시.

앱이나 테스트를 이 프록시 포트로 붙이고 조건을 걸면 서버는 살아 있는 채로
회선만 나빠진다. 서버 프로세스를 죽였다 살리는 것보다 빠르고, 다른 케이스가
쓰는 서버 상태를 건드리지 않는다.

만들 수 있는 조건 다섯 가지.

    close()          완전 단절. 이 시점부터 모든 요청이 실패한다.
    cut()            열린 연결만 끊는다. 리스너는 살아 있어 재연결은 된다.
    latency_ms       왕복 지연. 청크마다 이만큼 늦춰 보낸다.
    bandwidth_bps    대역폭 상한. 바이트 수에 비례해 늦춘다.
    freeze()         전송을 중간에 세운다. Charles breakpoint 자리다.
                     방향을 고를 수 있다. "down"은 요청은 보내고 응답만 세운다.

Charles를 쓰지 않은 이유는 재현성이다. GUI 도구는 증거가 스크린샷으로만 남고
CI에 넣을 수 없다. 여기 조건은 코드로 기록되고 그대로 다시 돌릴 수 있다.
"""
import socket
import threading
import time

FORWARD_HOST = "127.0.0.1"
FORWARD_PORT = 3000
CHUNK = 65536


class NetGate:
    def __init__(self, port=3999, forward_port=FORWARD_PORT):
        self.port = port
        self.forward_port = forward_port
        self.latency_ms = 0
        self.bandwidth_bps = 0        # 0이면 무제한
        self._server = None
        self._thread = None
        self._stop = threading.Event()
        self._flow = {"up": threading.Event(), "down": threading.Event()}
        for e in self._flow.values():
            e.set()                   # set이면 통과, clear면 정지
        self._live = []               # 열려 있는 소켓. cut()이 쓴다
        self._lock = threading.Lock()

    @property
    def base_url(self):
        return f"http://{FORWARD_HOST}:{self.port}/api/v1"

    # ---------- 열고 닫기 ----------
    def open(self):
        if self._server:
            return self
        self._stop.clear()
        self.thaw()
        self._server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self._server.bind((FORWARD_HOST, self.port))
        self._server.listen(64)
        self._server.settimeout(0.5)
        self._thread = threading.Thread(target=self._accept_loop, daemon=True)
        self._thread.start()
        return self

    def close(self):
        """완전 단절. 리스너까지 내려서 재연결도 안 된다."""
        self._stop.set()
        self.thaw()                   # 정지 상태로 두면 파이프 스레드가 안 끝난다
        self.cut()
        if self._server:
            self._server.close()
            self._server = None
        if self._thread:
            self._thread.join(timeout=3)
            self._thread = None
        return self

    def cut(self):
        """열린 연결만 끊는다. 전송 도중 회선이 끊기는 상황이다."""
        with self._lock:
            live, self._live = self._live, []
        for s in live:
            try:
                s.close()
            except OSError:
                pass
        return self

    # ---------- 조건 걸기 ----------
    def degrade(self, latency_ms=0, bandwidth_bps=0):
        """지연과 대역폭을 건다. 인자 없이 부르면 정상으로 되돌린다."""
        self.latency_ms = latency_ms
        self.bandwidth_bps = bandwidth_bps
        return self

    def freeze(self, direction="both"):
        """전송을 세운다.

        direction="down"이면 요청은 서버까지 가고 응답만 막힌다. 사용자가
        기다리다 이탈하는 상황이 이것이라, 서버는 이미 처리를 끝냈는데
        클라이언트만 모르는 상태가 된다. "both"는 요청부터 막아 서버에
        아무것도 닿지 않는다.
        """
        for k in (("up", "down") if direction == "both" else (direction,)):
            self._flow[k].clear()
        return self

    def thaw(self):
        for e in self._flow.values():
            e.set()
        return self

    def reset(self):
        return self.degrade().thaw()

    # ---------- 내부 ----------
    def _accept_loop(self):
        while not self._stop.is_set():
            try:
                client, _ = self._server.accept()
            except (OSError, socket.timeout):
                continue
            threading.Thread(target=self._pipe_pair, args=(client,), daemon=True).start()

    def _pipe_pair(self, client):
        try:
            upstream = socket.create_connection(
                (FORWARD_HOST, self.forward_port), timeout=10)
        except OSError:
            client.close()
            return
        with self._lock:
            self._live.extend((client, upstream))
        for src, dst, way in ((client, upstream, "up"), (upstream, client, "down")):
            threading.Thread(target=self._pipe, args=(src, dst, way), daemon=True).start()

    def _pipe(self, src, dst, way):
        try:
            while True:
                chunk = src.recv(CHUNK)
                if not chunk:
                    break
                self._throttle(len(chunk), way)
                dst.sendall(chunk)
        except OSError:
            pass
        finally:
            self._discard(src, dst)

    def _throttle(self, size, way):
        """지연과 대역폭을 여기서 한 번에 적용한다.

        정지(freeze)는 대기로 구현한다. 끊지 않아야 "응답이 안 온다"가 되고,
        끊으면 그건 단절이라 검증 대상이 달라진다.
        """
        while not self._flow[way].wait(timeout=0.25):
            if self._stop.is_set():
                return
        if self.latency_ms:
            time.sleep(self.latency_ms / 1000.0)
        if self.bandwidth_bps:
            time.sleep(size / float(self.bandwidth_bps))

    def _discard(self, *socks):
        with self._lock:
            for s in socks:
                if s in self._live:
                    self._live.remove(s)
        for s in socks:
            try:
                s.close()
            except OSError:
                pass
