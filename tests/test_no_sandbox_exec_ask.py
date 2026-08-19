"""Operator no-sandbox / YOLO flags must reach the agent env."""

import os

import api.streaming as streaming


def test_resolve_exec_ask_defaults_to_ask(monkeypatch):
    monkeypatch.delenv("HERMES_WEBUI_NO_SANDBOX", raising=False)
    monkeypatch.delenv("HERMES_NO_SANDBOX", raising=False)
    monkeypatch.delenv("HERMES_EXEC_ASK", raising=False)
    assert streaming._resolve_exec_ask() == "1"


def test_resolve_exec_ask_honors_webui_flag(monkeypatch):
    monkeypatch.setenv("HERMES_WEBUI_NO_SANDBOX", "1")
    monkeypatch.setenv("HERMES_EXEC_ASK", "1")
    assert streaming._resolve_exec_ask() == "0"


def test_build_agent_thread_env_sets_yolo(monkeypatch):
    monkeypatch.setenv("HERMES_WEBUI_NO_SANDBOX", "true")
    env = streaming._build_agent_thread_env({}, "/tmp/ws", "sid-1", "/tmp/home")
    assert env["HERMES_EXEC_ASK"] == "0"
    assert env["HERMES_YOLO_MODE"] == "1"
    assert env["TERMINAL_CWD"] == "/tmp/ws"
    assert env["HERMES_SESSION_PLATFORM"] == "webui"


def test_build_agent_thread_env_keeps_ask_by_default(monkeypatch):
    monkeypatch.delenv("HERMES_WEBUI_NO_SANDBOX", raising=False)
    monkeypatch.delenv("HERMES_NO_SANDBOX", raising=False)
    monkeypatch.delenv("HERMES_EXEC_ASK", raising=False)
    env = streaming._build_agent_thread_env({}, "/tmp/ws", "sid-1", "/tmp/home")
    assert env["HERMES_EXEC_ASK"] == "1"
    assert "HERMES_YOLO_MODE" not in env
