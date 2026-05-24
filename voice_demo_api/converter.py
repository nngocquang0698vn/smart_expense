import argparse
import subprocess
from pathlib import Path

import imageio_ffmpeg


def _run_ffmpeg(command: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        capture_output=True,
        text=True,
        timeout=60,
        check=False,
    )


def convert_aac_to_m4a(input_path: Path, output_path: Path) -> None:
    if not input_path.exists():
        raise FileNotFoundError(f"Input file not found: {input_path}")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()

    # First try a fast remux: keep AAC audio, put it in an M4A container.
    remux_command = [
        ffmpeg,
        "-y",
        "-hide_banner",
        "-loglevel",
        "error",
        "-i",
        str(input_path),
        "-vn",
        "-c:a",
        "copy",
        "-movflags",
        "+faststart",
        str(output_path),
    ]
    remux_result = _run_ffmpeg(remux_command)
    if remux_result.returncode == 0 and output_path.exists() and output_path.stat().st_size > 0:
        return

    # If the source AAC stream cannot be copied cleanly, re-encode to AAC in M4A.
    transcode_command = [
        ffmpeg,
        "-y",
        "-hide_banner",
        "-loglevel",
        "error",
        "-i",
        str(input_path),
        "-vn",
        "-c:a",
        "aac",
        "-b:a",
        "96k",
        "-movflags",
        "+faststart",
        str(output_path),
    ]
    transcode_result = _run_ffmpeg(transcode_command)
    if (
        transcode_result.returncode != 0
        or not output_path.exists()
        or output_path.stat().st_size == 0
    ):
        details = transcode_result.stderr.strip() or remux_result.stderr.strip()
        raise RuntimeError(f"ffmpeg conversion failed: {details or 'unknown error'}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert raw AAC audio to an M4A container for OpenAI transcription."
    )
    parser.add_argument(
        "input",
        nargs="?",
        default="samples/01.aac",
        help="Input AAC file. Default: samples/01.aac",
    )
    parser.add_argument(
        "output",
        nargs="?",
        default="samples/01.m4a",
        help="Output M4A file. Default: samples/01.m4a",
    )
    args = parser.parse_args()

    input_path = Path(args.input)
    output_path = Path(args.output)
    convert_aac_to_m4a(input_path=input_path, output_path=output_path)
    print(f"Converted {input_path} -> {output_path}")


if __name__ == "__main__":
    main()
