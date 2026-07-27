"""consent.find / consume, exercised against a real directory.

The assertions are about the FIELDS inside the token, not its filename.
Filenames cannot distinguish a `handed-off` token from a `not-a-defect` one,
and on 2026-07-27 the case that mattered most passed both before and after a
fix until the content was pinned.
"""
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "lib"))
import consent


def write_token(tokens_dir, kind, subject="alpha", actor="user", phrase="ok"):
    os.makedirs(tokens_dir, exist_ok=True)
    p = os.path.join(tokens_dir, kind + ".token")
    with open(p, "w", encoding="utf-8") as fh:
        fh.write("kind: %s\nsubject: %s\nactor: %s\nphrase: %s\n"
                 % (kind, subject, actor, phrase))
    return p


class FindTests(unittest.TestCase):
    def test_absent_token_is_none(self):
        with tempfile.TemporaryDirectory() as td:
            self.assertIsNone(consent.find(td, "scope-proposed--scope-approved"))

    def test_present_token_is_found(self):
        with tempfile.TemporaryDirectory() as td:
            p = write_token(td, "scope-proposed--scope-approved")
            self.assertEqual(consent.find(td, "scope-proposed--scope-approved"), p)

    def test_empty_token_is_not_found(self):
        with tempfile.TemporaryDirectory() as td:
            os.makedirs(td, exist_ok=True)
            open(os.path.join(td, "k.token"), "w").close()
            self.assertIsNone(consent.find(td, "k"))

    def test_unsafe_kind_raises(self):
        with tempfile.TemporaryDirectory() as td:
            for bad in ("../escape", "a/b", "", "-lead", "." , "..", "foo\n"):
                with self.assertRaises(ValueError):
                    consent.token_path(td, bad)


class ConsumeTests(unittest.TestCase):
    def test_consume_returns_fields_and_removes(self):
        with tempfile.TemporaryDirectory() as td:
            write_token(td, "reproduced--handed-off", subject="F-1",
                        phrase="item F-1 confirmed defect")
            got = consent.consume(td, "reproduced--handed-off")
            self.assertEqual(got["kind"], "reproduced--handed-off")
            self.assertEqual(got["subject"], "F-1")
            self.assertEqual(got["actor"], "user")
            self.assertEqual(got["phrase"], "item F-1 confirmed defect")
            self.assertIsNone(consent.find(td, "reproduced--handed-off"))

    def test_second_consume_raises(self):
        """A token that survives its use is a standing approval. Measured
        2026-07-27: one repo never removed it, so the same approving write
        passed four times in a row."""
        with tempfile.TemporaryDirectory() as td:
            write_token(td, "k")
            consent.consume(td, "k")
            with self.assertRaises(consent.ConsentError):
                consent.consume(td, "k")

    def test_absent_raises(self):
        with tempfile.TemporaryDirectory() as td:
            with self.assertRaises(consent.ConsentError):
                consent.consume(td, "k")

    def test_malformed_raises_and_leaves_file(self):
        """Fail closed: a malformed token is refused and the file survives.
        With claim-first-keep-claimed, the file is left at the claimed path
        (.token.claimed-<pid>) where it will not be found by find() but can be
        recovered by a human who reads the error message. The message must name
        the claimed path."""
        with tempfile.TemporaryDirectory() as td:
            p = os.path.join(td, "k.token")
            with open(p, "w") as fh:
                fh.write("this is not a token\n")
            try:
                consent.consume(td, "k")
                self.fail("Expected ConsentError")
            except consent.ConsentError as e:
                error_msg = str(e)
                # The error message must name the claimed path
                self.assertIn(".claimed-", error_msg)
                # Extract the claimed path: it's the path between "at " and " is"
                import re
                match = re.search(r"at ([^\s]+\.claimed-\d+)", error_msg)
                self.assertIsNotNone(match, f"Error message did not name claimed path: {error_msg}")
                claimed_path = match.group(1)
                self.assertTrue(os.path.isfile(claimed_path),
                                f"File not found at claimed path: {claimed_path}")

    def test_invalid_utf8_raises_and_leaves_file(self):
        """UnicodeDecodeError on invalid UTF-8 bytes must raise ConsentError.
        The claimed token survives at the claimed path, not the original path."""
        with tempfile.TemporaryDirectory() as td:
            p = os.path.join(td, "k.token")
            # Write a token with an invalid UTF-8 byte sequence
            with open(p, "wb") as fh:
                fh.write(b"kind: k\nsubject: a\nactor: user\nphrase: bad-\xff-byte\n")
            try:
                consent.consume(td, "k")
                self.fail("Expected ConsentError")
            except consent.ConsentError as e:
                error_msg = str(e)
                # The error message must name the claimed path
                self.assertIn(".claimed-", error_msg)
                # Extract and verify the claimed file exists
                import re
                match = re.search(r"at ([^\s]+\.claimed-\d+)", error_msg)
                self.assertIsNotNone(match, f"Error message did not name claimed path: {error_msg}")
                claimed_path = match.group(1)
                self.assertTrue(os.path.isfile(claimed_path),
                                f"Claimed file not found: {claimed_path}")
                # Original path should not exist
                self.assertFalse(os.path.isfile(p),
                                 f"Original path should not exist: {p}")

    def test_claim_failure_raises_consent_error(self):
        """The claim rename is the single-use guard. If the claim fails,
        ConsentError is raised (not a raw OSError). This guards the race: two
        consumers both read and validate the same token, then race to claim it.
        Exactly one rename succeeds; the loser's OSError becomes ConsentError.
        Removing this guard would let OSError escape."""
        with tempfile.TemporaryDirectory() as td:
            write_token(td, "k")

            # Patch os.rename in consent module to fail on claim
            original_rename = consent.os.rename

            def failing_rename(src, dst):
                raise FileNotFoundError("simulated claim failure")

            consent.os.rename = failing_rename
            try:
                with self.assertRaises(consent.ConsentError):
                    consent.consume(td, "k")
            finally:
                consent.os.rename = original_rename


if __name__ == "__main__":
    unittest.main()
