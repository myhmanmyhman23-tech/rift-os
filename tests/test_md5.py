import hashlib
import pathlib
import subprocess
import sys
import tempfile
import unittest


class MediumIntegrityTests(unittest.TestCase):
    def test_remastered_entries_change_and_other_files_keep_their_hash(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            names = ("filesystem.squashfs", "filesystem.manifest", "filesystem.size")
            for name in names:
                (root / name).write_bytes(f"new {name}".encode())
            old = root / "old.txt"
            old.write_text("\n".join(
                [f"{'0' * 32}  ./casper/{name}" for name in names]
                + [f"{'a' * 32}  ./boot/grub/grub.cfg"]
            ) + "\n")
            output = root / "updated.txt"
            subprocess.run([
                sys.executable, str(pathlib.Path(__file__).parents[1] / "build/update-md5.py"),
                str(old), str(root), str(output),
            ], check=True)
            lines = output.read_text().splitlines()
            for index, name in enumerate(names):
                expected = hashlib.md5((root / name).read_bytes()).hexdigest()
                self.assertEqual(lines[index], f"{expected}  ./casper/{name}")
            self.assertEqual(lines[-1], f"{'a' * 32}  ./boot/grub/grub.cfg")


if __name__ == "__main__":
    unittest.main()
