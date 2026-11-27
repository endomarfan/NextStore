import os
import subprocess
import sys
import tempfile
import unittest

SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "release.py")


class ReleaseTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dir = tempfile.TemporaryDirectory()
        cls.path = cls.dir.name
        cls.git("init", "-q", "-b", "develop")
        cls.git("config", "user.email", "t@example.com")
        cls.git("config", "user.name", "t")
        cls.git("config", "commit.gpgsign", "false")
        cls.commit("chore: base")
        cls.fork_point = cls.git("rev-parse", "HEAD")
        cls.commit("feat(ui): add thing")
        cls.git("tag", "v1.0.0-beta.1")
        cls.commit("fix!: repair pairing (#7)")
        cls.git("tag", "v1.0.0-beta.2")
        cls.commit("ci: tweak workflow")
        cls.git("tag", "v1.0.0")
        cls.commit("feat: second feature")
        cls.git("tag", "v1.0.1-beta.1")
        cls.commit("plain subject without prefix")
        cls.git("tag", "v1.0.1-beta.3")
        cls.ipa = os.path.join(cls.path, "SideStore.ipa")
        with open(cls.ipa, "wb") as f:
            f.write(b"ipa")

    @classmethod
    def tearDownClass(cls):
        cls.dir.cleanup()

    @classmethod
    def git(cls, *args):
        return subprocess.run(["git", *args], cwd=cls.path, capture_output=True, text=True, check=True).stdout.strip()

    @classmethod
    def commit(cls, subject):
        cls.git("commit", "-q", "--allow-empty", "-m", subject)

    def run_script(self, *args):
        env = dict(os.environ, RELEASE_FORK_POINT=self.fork_point)
        return subprocess.run([sys.executable, SCRIPT, *args], cwd=self.path, capture_output=True, text=True, env=env)

    def notes(self, kind, **extra):
        args = ["notes", "--kind", kind, "--version", "V", "--sha", "HEAD", "--repo", "o/r", "--ipa", self.ipa]
        for key, value in extra.items():
            args += [f"--{key.replace('_', '-')}", value]
        result = self.run_script(*args)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    def test_next_beta_no_tags(self):
        result = self.run_script("next-beta", "--base", "2.0.0")
        self.assertEqual(result.stdout.strip(), "1")

    def test_next_beta_released_base(self):
        result = self.run_script("next-beta", "--base", "1.0.0")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("v1.0.0 is already released; bump MARKETING_VERSION in Build.xcconfig first", result.stderr)

    def test_next_beta_after_gap(self):
        result = self.run_script("next-beta", "--base", "1.0.1")
        self.assertEqual(result.stdout.strip(), "4")

    def test_beta_notes_previous_tag_and_groups(self):
        out = self.notes("beta", tag="v1.0.1-beta.4")
        self.assertIn("> **Beta** for testing.", out)
        self.assertIn("## What's changed since v1.0.1-beta.3", out)
        self.assertIn("No changes since v1.0.1-beta.3.", out)
        self.assertIn("compare/v1.0.1-beta.3...v1.0.1-beta.4", out)
        self.assertIn("SHA-256 of SideStore.ipa:", out)

    def test_nightly_notes(self):
        self.commit("fix(core): nightly only fix")
        try:
            out = self.notes("nightly")
        finally:
            self.git("reset", "-q", "--hard", "HEAD^")
        self.assertIn("> [!WARNING]", out)
        self.assertIn("## What's changed since v1.0.1-beta.3", out)
        self.assertIn("### Fixes\n- Nightly only fix (", out)
        self.assertNotIn("### New", out)
        self.assertNotIn("Full changelog", out)

    def test_stable_notes_use_stable_tags_only(self):
        out = self.notes("stable", tag="v1.0.2", promoted_from="v1.0.1-beta.3")
        self.assertIn("Promoted from **v1.0.1-beta.3** after device testing.", out)
        self.assertIn("## What's changed since v1.0.0", out)
        self.assertIn("### New\n- Second feature (", out)
        self.assertIn("### Other changes\n- Plain subject without prefix (", out)
        self.assertNotIn("### Fixes", out)
        self.assertIn("compare/v1.0.0...v1.0.2", out)

    def test_tag_on_head_uses_parent(self):
        out = self.notes("beta", tag="v1.0.1-beta.3")
        self.assertIn("## What's changed since v1.0.1-beta.1", out)
        self.assertIn("- Plain subject without prefix (", out)

    def test_prefix_stripping_and_pr_number(self):
        self.git("checkout", "-q", "v1.0.0-beta.2")
        try:
            out = self.notes("beta", tag="v1.0.0-beta.2")
        finally:
            self.git("checkout", "-q", "develop")
        self.assertIn("## What's changed since v1.0.0-beta.1", out)
        self.assertIn("### Fixes\n- Repair pairing (#7) ([", out)
        self.assertNotIn("fix!:", out)

    def test_fork_point_fallback(self):
        self.git("checkout", "-q", self.fork_point)
        self.commit("feat: before any tag")
        try:
            out = self.notes("beta", tag="v0.0.1-beta.1")
        finally:
            self.git("reset", "-q", "--hard", "HEAD^")
            self.git("checkout", "-q", "develop")
        self.assertIn("## What's changed since the fork from SideStore", out)
        self.assertIn("- Before any tag (", out)

    def test_highlights(self):
        path = os.path.join(self.path, "h.md")
        with open(path, "w") as f:
            f.write("Big news\n")
        out = self.notes("beta", tag="v1.0.1-beta.4", highlights=path)
        self.assertIn("\n\nBig news\n\n**Version**", out)


if __name__ == "__main__":
    unittest.main()
