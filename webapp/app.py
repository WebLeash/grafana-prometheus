from flask import Flask, request, Response
from prometheus_client import Counter, Histogram, generate_latest

app = Flask(__name__)

REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP Requests (count)', ['method', 'endpoint'])
REQUEST_LATENCY = Histogram('http_request_latency_seconds', 'HTTP request latency (seconds)', ['endpoint'])

@app.route('/')
def hello_world():
    with REQUEST_LATENCY.labels('/').time():
        REQUEST_COUNT.labels(request.method, '/').inc()
        return '<html><body><h1>Hello, World!</h1></body></html>'

@app.route('/metrics')
def metrics():
    return Response(generate_latest(), mimetype='text/plain')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
