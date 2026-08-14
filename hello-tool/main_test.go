package main

import (
	"bytes"
	"strings"
	"testing"
)

func TestRunGreeting(t *testing.T) {
	var stdout, stderr bytes.Buffer
	if code := run([]string{"-name", "Flyxion"}, &stdout, &stderr); code != 0 {
		t.Fatalf("run returned %d; stderr: %s", code, stderr.String())
	}
	if got, want := stdout.String(), "Hello, Flyxion!\n"; got != want {
		t.Fatalf("stdout = %q, want %q", got, want)
	}
}

func TestRunVersion(t *testing.T) {
	oldVersion := version
	version = "v1.2.3"
	t.Cleanup(func() { version = oldVersion })

	var stdout, stderr bytes.Buffer
	if code := run([]string{"-version"}, &stdout, &stderr); code != 0 {
		t.Fatalf("run returned %d; stderr: %s", code, stderr.String())
	}
	if got, want := strings.TrimSpace(stdout.String()), "v1.2.3"; got != want {
		t.Fatalf("version = %q, want %q", got, want)
	}
}

func TestRunRejectsUnexpectedArgument(t *testing.T) {
	var stdout, stderr bytes.Buffer
	if code := run([]string{"extra"}, &stdout, &stderr); code != 2 {
		t.Fatalf("run returned %d, want 2", code)
	}
}
