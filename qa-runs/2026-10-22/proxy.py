import json, threading
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import requests

out = Path(__file__).parent / 'evidence/http.jsonl'
lock = threading.Lock()
def redact(x):
    if isinstance(x, dict):
        return {k: ('[REDACTED]' if any(s in k.lower() for s in ('token','password','secret')) else redact(v)) for k,v in x.items()}
    if isinstance(x,list): return [redact(v) for v in x]
    return x
def decode(x):
    try: return redact(json.loads(x))
    except Exception: return x.decode(errors='replace')[:1000]
class Proxy(BaseHTTPRequestHandler):
    def run_request(self):
        body = self.rfile.read(int(self.headers.get('Content-Length',0)))
        headers = {k:v for k,v in self.headers.items() if k.lower() not in ('host','content-length','connection','accept-encoding')}
        r = requests.request(self.command, 'http://127.0.0.1:3301'+self.path, headers=headers, data=body, timeout=30)
        record = dict(at=datetime.now(timezone.utc).isoformat(),method=self.command,path=self.path,request=decode(body),status=r.status_code,response=decode(r.content))
        with lock, out.open('a') as f: f.write(json.dumps(record,ensure_ascii=False)+'\n')
        self.send_response(r.status_code)
        self.send_header('Content-Type',r.headers.get('Content-Type','application/json'))
        self.send_header('Content-Length',str(len(r.content)))
        self.end_headers(); self.wfile.write(r.content)
    do_GET = do_POST = do_PATCH = do_DELETE = do_PUT = run_request
    def log_message(self,*args): pass
ThreadingHTTPServer(('127.0.0.1',3300),Proxy).serve_forever()
