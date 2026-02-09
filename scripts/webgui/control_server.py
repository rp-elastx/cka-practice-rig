#!/usr/bin/env python3
import os, json, subprocess
from flask import Flask, jsonify, request

app = Flask(__name__)
REPO_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
KUBECONFIG_MERGED = os.path.join(REPO_DIR, 'kubeconfigs', 'merged.yaml')
SCORE_DIR = os.path.join(REPO_DIR, 'scoreboard')
SESSION_FILE = os.path.join(SCORE_DIR, 'current-session.json')
BROADCAST_FILE = os.path.join(SCORE_DIR, 'broadcast.json')

ENV = os.environ.copy()
ENV['KUBECONFIG'] = KUBECONFIG_MERGED

@app.get('/api/status')
def status():
    cur = None
    meta = None
    results = None
    if os.path.exists(SESSION_FILE):
        with open(SESSION_FILE) as f:
            cur = json.load(f)
    if os.path.exists(os.path.join(SCORE_DIR,'session.json')):
        with open(os.path.join(SCORE_DIR,'session.json')) as f:
            meta = json.load(f)
    if os.path.exists(os.path.join(SCORE_DIR,'results.json')):
        with open(os.path.join(SCORE_DIR,'results.json')) as f:
            results = json.load(f)
    # Check for broadcast message
    broadcast = None
    if os.path.exists(BROADCAST_FILE):
        try:
            with open(BROADCAST_FILE) as f:
                broadcast = json.load(f)
        except: pass
    
    if cur:
        if meta:
            cur['sessionStart'] = meta.get('sessionStart')
            cur['totalTimeLimitSeconds'] = meta.get('totalTimeLimitSeconds', 7200)
            cur['total'] = meta.get('total', cur.get('total'))
            cur['index'] = cur.get('index', meta.get('currentIndex', 0))
        # Add completed/passed counts from results
        if results and meta:
            session_id = meta.get('sessionId')
            session_results = [r for r in results if r.get('sessionId') == session_id]
            cur['completed'] = len(session_results)
            cur['passed'] = len([r for r in session_results if r.get('pass')])
        if broadcast:
            cur['broadcast'] = broadcast
        return jsonify(cur)
    resp = {"status":"idle"}
    if broadcast:
        resp['broadcast'] = broadcast
    return jsonify(resp)

@app.post('/api/start-session')
def start_session():
    try:
        subprocess.check_call(['bash', os.path.join(REPO_DIR, 'scripts', 'session', 'start.sh')], env=ENV)
        with open(SESSION_FILE) as f:
            return jsonify(json.load(f))
    except subprocess.CalledProcessError as e:
        return jsonify({"error":"failed to start session","detail":str(e)}), 500

@app.post('/api/reset')
def reset():
    try:
        subprocess.check_call(['bash', os.path.join(REPO_DIR, 'scripts', 'reset.sh')], env=ENV)
        return jsonify({"status":"reset"})
    except subprocess.CalledProcessError as e:
        return jsonify({"error":"failed to reset","detail":str(e)}), 500

@app.post('/api/done')
def done():
    try:
        subprocess.check_call(['bash', os.path.join(REPO_DIR, 'scripts', 'session', 'done.sh')], env=ENV)
        with open(SESSION_FILE) as f:
            return jsonify(json.load(f))
    except subprocess.CalledProcessError as e:
        return jsonify({"error":"failed to grade","detail":str(e)}), 500

@app.post('/api/next-challenge')
def next_challenge():
    try:
        subprocess.check_call(['bash', os.path.join(REPO_DIR, 'scripts', 'session', 'next.sh')], env=ENV)
        with open(SESSION_FILE) as f:
            return jsonify(json.load(f))
    except subprocess.CalledProcessError as e:
        return jsonify({"error":"failed to load next","detail":str(e)}), 500

@app.post('/api/prev-challenge')
def prev_challenge():
    try:
        subprocess.check_call(['bash', os.path.join(REPO_DIR, 'scripts', 'session', 'prev.sh')], env=ENV)
        with open(SESSION_FILE) as f:
            return jsonify(json.load(f))
    except subprocess.CalledProcessError as e:
        return jsonify({"error":"failed to load previous","detail":str(e)}), 500

@app.post('/api/sync-scoreboard')
def sync_scoreboard():
    try:
        subprocess.check_call(['rsync', '-a', SCORE_DIR + '/', '/var/www/cka-practice/scoreboard/'])
        return jsonify({"status":"synced"})
    except subprocess.CalledProcessError as e:
        return jsonify({"error":"failed to sync","detail":str(e)}), 500

@app.post('/api/broadcast')
def broadcast():
    """Set a broadcast message to display on all clients"""
    data = request.get_json() or {}
    msg = data.get('message', '')
    msg_type = data.get('type', 'info')  # info, warning, error, reset
    if msg:
        with open(BROADCAST_FILE, 'w') as f:
            json.dump({'message': msg, 'type': msg_type}, f)
    return jsonify({"status": "broadcast set", "message": msg})

@app.post('/api/clear-broadcast')
def clear_broadcast():
    """Clear the broadcast message"""
    if os.path.exists(BROADCAST_FILE):
        os.remove(BROADCAST_FILE)
    return jsonify({"status": "cleared"})

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5005)
