"""완전 단절을 만들었다 푸는 TCP 프록시.

앱을 이 프록시 포트로 띄우고, 프록시를 닫으면 서버는 살아 있는 채로 앱만 끊긴다.
서버 프로세스를 죽였다 살리는 것보다 빠르고, 다른 케이스가 쓰는 서버 상태를 건드리지 않는다.
"""
import socket
import threading

FORWARD_HOST = "127.0.0.1"
FORWARD_PORT = 3000


class NetGate:
    def __init__(self, port=3999):
        self.port = port
        self._server = None
        self._thread = None
        self._stop = threading.Event()

    @property
    def base_url(self):
        return f"http://{FORWARD_HOST}:{self.port}/api/v1"

    def open(self):
        if self._server:
            return self
        self._stop.clear()
        self._server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self._server.bind((FORWARD_HOST, self.port))
        self._server.listen(64)
        self._server.settimeout(0.5)
        self._thread = threading.Thread(target=self._accept_loop, daemon=True)
        self._thread.start()
        return self

    def close(self):
        """연결을 끊는다. 이 시점부터 앱의 모든 요청이 실패한다."""
        self._stop.set()
        if self._server:
            self._server.close()
            self._server = None
        if self._thread:
            self._thread.join(timeout=3)
            self._thread = None
        return self

    def _accept_loop(self):
        while not self._stop.is_set():
            try:
                client, _ = self._server.accept()
            except (OSError, socket.timeout):
                continue
            threading.Thread(target=self._pipe_pair, args=(client,), daemon=True).start()

    def _pipe_pair(self, client):
        try:
            upstream = socket.create_connection((FORWARD_HOST, FORWARD_PORT), timeout=10)
        except OSError:
            client.close()
            return
        for src, dst in ((client, upstream), (upstream, client)):
            threading.Thread(target=self._pipe, args=(src, dst), daemon=True).start()

    @staticmethod
    def _pipe(src, dst):
        try:
            while True:
                chunk = src.recv(65536)
                if not chunk:
                    break
                dst.sendall(chunk)
        except OSError:
            pass
        finally:
            for s in (src, dst):
                try:
                    s.close()
                except OSError:
                    pass
