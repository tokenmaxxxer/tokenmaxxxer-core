#!/usr/bin/env python3
"""judge.maybe_mint: mints only on a clean structured APPROVE from the judge
session.

The subprocess is injected via `cmd` so these tests never invoke a real model.
Every case that is not an unambiguous APPROVE must leave no token behind.

The verdict is read from --output-format json's structured_output (enforced by
--json-schema in the default cmd), not from a first line of prose — anything
that does not parse to exactly {"structured_output": {"verdict": "APPROVE",
"reasoning": <non-empty>}} is False.
"""
import json
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import consent  # noqa: E402
import judge    # noqa: E402

KIND = "scope-proposed--scope-approved"
SUB = "2026-07-27-laundry-drying-time"


def fake(stdout, code=0, sleep=0.0):
    """A cmd stand-in: a python one-liner that prints and exits as told."""
    body = "import sys, time; time.sleep(%r); sys.stdout.write(%r); sys.exit(%d)" % (
        sleep, stdout, code)
    return [sys.executable, "-c", body]


def verdict_json(verdict, reasoning="Write surface is inside docs/."):
    return json.dumps({"structured_output": {"verdict": verdict,
                                             "reasoning": reasoning}})


class MaybeMint(unittest.TestCase):
    def setUp(self):
        # The tokens directory must be NESTED, mirroring production's
        # records/<subject>/tokens/. maybe_mint writes its audit line to the
        # PARENT of tokens_dir, so a bare mkdtemp() put judge-log.md straight
        # into the shared system temp directory: measured 2026-07-27, 4KB of
        # verdicts accumulated there across runs, and the log assertion below
        # was passing on entries from previous runs.
        self.root = tempfile.mkdtemp()
        self.dir = os.path.join(self.root, "records", SUB, "tokens")
        os.makedirs(self.dir)
        self.log = os.path.join(self.root, "records", SUB, "judge-log.md")
        self.env = dict(os.environ, TOKENMAXXXER_UNATTENDED="1")
        self.env.pop("CORE_OFF", None)

    def run_it(self, cmd, timeout=30, env=None):
        return judge.maybe_mint(
            self.dir, KIND, SUB,
            material="a scope statement",
            facts="3 files changed, all under docs/",
            cmd=cmd, timeout=timeout, env=env if env is not None else self.env)

    def token(self):
        p = os.path.join(self.dir, KIND + ".token")
        return open(p, encoding="utf-8").read() if os.path.exists(p) else None

    def test_approve_mints_with_actor_judge(self):
        self.assertTrue(self.run_it(fake(verdict_json("APPROVE"))))
        t = self.token()
        self.assertIn("actor: judge", t)
        self.assertIn("kind: " + KIND, t)
        self.assertIn("subject: " + SUB, t)
        self.assertIn("Write surface is inside docs/.", t)

    def test_approved_token_is_consumable_by_an_unattended_gate(self):
        # The whole point: the minted token must satisfy consent.consume with
        # the unattended allow-list — as shipped before this slice, judge
        # tokens were dead on arrival (consume hard-refused actor != user).
        self.assertTrue(self.run_it(fake(verdict_json("APPROVE"))))
        got = consent.consume(self.dir, KIND, allowed_actors=("user", "judge"))
        self.assertEqual(got["actor"], "judge")
        self.assertEqual(got["subject"], SUB)

    def test_refuse_mints_nothing(self):
        self.assertFalse(self.run_it(fake(verdict_json("REFUSE"))))
        self.assertIsNone(self.token())

    def test_hold_mints_nothing(self):
        self.assertFalse(self.run_it(fake(verdict_json("HOLD"))))
        self.assertIsNone(self.token())

    def test_verdict_must_be_exact(self):
        for v in ("approve", "APPROVE ", "APPROVE_NOT", "", "The answer is APPROVE"):
            self.assertFalse(self.run_it(fake(verdict_json(v))), v)
            self.assertIsNone(self.token(), v)

    def test_unstructured_output_mints_nothing(self):
        for out in ("APPROVE\nWrite surface is inside docs/.\n",      # prose, old contract
                    json.dumps({"verdict": "APPROVE"}),               # wrong nesting
                    json.dumps({"structured_output": "APPROVE"}),     # wrong type
                    "not json at all"):
            self.assertFalse(self.run_it(fake(out)), out)
            self.assertIsNone(self.token(), out)

    def test_empty_reasoning_mints_nothing(self):
        # phrase is required by consume(); a token with an empty phrase would
        # be unconsumable — refuse to mint it at all.
        self.assertFalse(self.run_it(fake(verdict_json("APPROVE", reasoning=""))))
        self.assertIsNone(self.token())

    def test_empty_output_mints_nothing(self):
        self.assertFalse(self.run_it(fake("")))
        self.assertIsNone(self.token())

    def test_nonzero_exit_mints_nothing(self):
        self.assertFalse(self.run_it(fake(verdict_json("APPROVE"), code=1)))
        self.assertIsNone(self.token())

    def test_timeout_mints_nothing(self):
        self.assertFalse(self.run_it(fake(verdict_json("APPROVE"), sleep=3), timeout=1))
        self.assertIsNone(self.token())

    def test_missing_binary_mints_nothing(self):
        self.assertFalse(self.run_it(["/nonexistent/judge-binary", "-p"]))
        self.assertIsNone(self.token())

    def test_attended_never_spawns(self):
        # No TOKENMAXXXER_UNATTENDED: the judge is inert even if the
        # subprocess would have approved. A human is present; the human
        # decides.
        env = dict(os.environ)
        env.pop("TOKENMAXXXER_UNATTENDED", None)
        self.assertFalse(self.run_it(fake(verdict_json("APPROVE")), env=env))
        self.assertIsNone(self.token())

    def test_core_off_never_spawns(self):
        env = dict(self.env, CORE_OFF="1")
        self.assertFalse(self.run_it(fake(verdict_json("APPROVE")), env=env))
        self.assertIsNone(self.token())

    def test_bad_kind_or_subject_mints_nothing(self):
        for k, s in (("../escape", SUB), (KIND, "../escape"),
                     ("", SUB), (KIND, "")):
            self.assertFalse(judge.maybe_mint(
                self.dir, k, s, material="m", facts="f",
                cmd=fake(verdict_json("APPROVE")), env=self.env), (k, s))

    def test_judge_log_survives_the_verdict(self):
        """The token is consumed and deleted; the log line is what a human
        audits afterwards.

        Asserted on the reasoning THIS call carried, not on KIND/SUB — those
        are constants, so the earlier version of this test passed on a stale
        log written by any previous run and could not fail.
        """
        self.assertFalse(os.path.exists(self.log))
        mark = "verdict-line-unique-to-this-call"
        self.assertTrue(self.run_it(fake(verdict_json("APPROVE", reasoning=mark))))
        text = open(self.log, encoding="utf-8").read()
        self.assertEqual(text.count("\n"), 1)
        self.assertIn(mark, text)
        self.assertIn("APPROVE", text)
        self.assertIn(KIND, text)
        self.assertIn(SUB, text)

    def test_refused_verdicts_are_logged_too(self):
        # The token is what a gate reads; the log is what a human reads. A
        # REFUSE that leaves no trace is an unattended decision nobody can
        # audit afterwards.
        self.assertFalse(self.run_it(fake(verdict_json("REFUSE", reasoning="touches .github"))))
        self.assertIsNone(self.token())
        self.assertIn("REFUSE", open(self.log, encoding="utf-8").read())

    def test_nothing_is_written_outside_the_root(self):
        # maybe_mint writes exactly two paths: the token and the audit line,
        # both under the caller's tree.
        self.assertTrue(self.run_it(fake(verdict_json("APPROVE"))))
        found = set()
        for base, _dirs, files in os.walk(self.root):
            for f in files:
                found.add(os.path.relpath(os.path.join(base, f), self.root))
        self.assertEqual(found, {
            os.path.join("records", SUB, "tokens", KIND + ".token"),
            os.path.join("records", SUB, "judge-log.md"),
        })


if __name__ == "__main__":
    unittest.main()
