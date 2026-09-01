"""Build the non-canonical, human-readable Tetris game blueprint PDF.

The repository design owners remain canonical.  This utility only renders their
current, bounded synthesis and records byte-level provenance for readers.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import tempfile
from datetime import datetime, timezone
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    Image,
    KeepTogether,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "docs" / "blueprints"
PDF_PATH = OUTPUT_DIR / "TETRIS_HUMAN_GAME_BLUEPRINT.pdf"
MANIFEST_PATH = OUTPUT_DIR / "TETRIS_HUMAN_GAME_BLUEPRINT.manifest.json"
FONT_PATH = Path("C:/Windows/Fonts/malgun.ttf")
FONT_BOLD_PATH = Path("C:/Windows/Fonts/malgunbd.ttf")
BOSS_ART_PATH = ROOT / "assets" / "production" / "bosses" / "gatebreaker_combat_cutout_v2.png"

SOURCE_PATHS = [
    "docs/design/PROJECT_MASTER_GDD.md",
    "docs/design/PRODUCTION_REALTIME_COMBAT_CANON.md",
    "docs/design/COMBO_RESOLVED_SKILL_CONTRACT.md",
    "docs/design/CHAIN_COMBO_MP_CONTRACT.md",
    "docs/design/RUNTIME_IMAGE_ASSET_CONSUMER_CONTRACT.md",
    "docs/design/VISUAL_BIBLE.md",
    "docs/design/FIRST_SESSION_ONBOARDING_CONTRACT.md",
    "docs/design/FULL_GAME_SCREEN_SURFACE_INVENTORY.md",
    "docs/assets/reference/approved/APPROVED_REFERENCE_MANIFEST.json",
]

PARCHMENT = colors.HexColor("#F3E7CE")
INK = colors.HexColor("#241C18")
SEPIA = colors.HexColor("#765537")
VIOLET = colors.HexColor("#6F3E95")
GOLD = colors.HexColor("#B88B3D")
MUTED = colors.HexColor("#62574D")
PANEL = colors.HexColor("#FFF9EC")
BLUE = colors.HexColor("#265A86")
RED = colors.HexColor("#8B342E")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def repository_head() -> str:
    completed = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=ROOT,
        check=True,
        text=True,
        capture_output=True,
    )
    return completed.stdout.strip()


def register_font() -> str:
    if FONT_PATH.is_file() and FONT_BOLD_PATH.is_file():
        pdfmetrics.registerFont(TTFont("TetrisBlueprint", str(FONT_PATH)))
        pdfmetrics.registerFont(TTFont("TetrisBlueprintBold", str(FONT_BOLD_PATH)))
        pdfmetrics.registerFontFamily(
            "TetrisBlueprint",
            normal="TetrisBlueprint",
            bold="TetrisBlueprintBold",
            italic="TetrisBlueprint",
            boldItalic="TetrisBlueprintBold",
        )
        return "TetrisBlueprint"
    return "Helvetica"


def paragraph(text: str, style: ParagraphStyle) -> Paragraph:
    return Paragraph(text, style)


def source_records() -> list[dict[str, str]]:
    records = []
    for relative_path in SOURCE_PATHS:
        source = ROOT / relative_path
        if not source.is_file():
            raise FileNotFoundError(f"required blueprint source is missing: {source}")
        records.append({"path": relative_path, "sha256": sha256(source)})
    return records


def styles_for(font_name: str) -> dict[str, ParagraphStyle]:
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "BlueprintTitle",
            parent=base["Title"],
            fontName=font_name,
            fontSize=24,
            leading=31,
            alignment=TA_CENTER,
            textColor=INK,
            spaceAfter=6,
        ),
        "subtitle": ParagraphStyle(
            "BlueprintSubtitle",
            parent=base["Normal"],
            fontName=font_name,
            fontSize=10,
            leading=15,
            alignment=TA_CENTER,
            textColor=SEPIA,
            spaceAfter=12,
        ),
        "heading": ParagraphStyle(
            "BlueprintHeading",
            parent=base["Heading2"],
            fontName=font_name,
            fontSize=14,
            leading=19,
            textColor=INK,
            spaceBefore=12,
            spaceAfter=6,
        ),
        "body": ParagraphStyle(
            "BlueprintBody",
            parent=base["BodyText"],
            fontName=font_name,
            fontSize=9.1,
            leading=14,
            textColor=INK,
            spaceAfter=5,
        ),
        "small": ParagraphStyle(
            "BlueprintSmall",
            parent=base["BodyText"],
            fontName=font_name,
            fontSize=7.4,
            leading=10,
            textColor=MUTED,
        ),
        "cell": ParagraphStyle(
            "BlueprintCell",
            parent=base["BodyText"],
            fontName=font_name,
            fontSize=8.1,
            leading=11.2,
            textColor=INK,
        ),
        "cell_head": ParagraphStyle(
            "BlueprintCellHead",
            parent=base["BodyText"],
            fontName=font_name,
            fontSize=8.1,
            leading=11.2,
            textColor=colors.white,
            alignment=TA_CENTER,
        ),
        "hero": ParagraphStyle(
            "BlueprintHero",
            parent=base["BodyText"],
            fontName=font_name,
            fontSize=12,
            leading=18,
            alignment=TA_CENTER,
            textColor=VIOLET,
            spaceAfter=8,
        ),
    }


def cell_table(
    rows: list[list[str]],
    widths: list[float],
    styles: dict[str, ParagraphStyle],
    header: bool = True,
) -> Table:
    rendered = []
    for index, row in enumerate(rows):
        active = styles["cell_head"] if header and index == 0 else styles["cell"]
        rendered.append([paragraph(value, active) for value in row])
    table = Table(rendered, colWidths=widths, repeatRows=1 if header else 0, hAlign="LEFT")
    commands = [
        ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#B59565")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ("BACKGROUND", (0, 0), (-1, 0), INK if header else PANEL),
    ]
    if header and len(rows) > 1:
        for row_index in range(1, len(rows)):
            if row_index % 2 == 0:
                commands.append(("BACKGROUND", (0, row_index), (-1, row_index), colors.HexColor("#F8EEDC")))
    table.setStyle(TableStyle(commands))
    return table


def panel(title: str, body: str, styles: dict[str, ParagraphStyle], width: float) -> Table:
    table = Table(
        [[paragraph(f"<b>{title}</b>", styles["cell"]), paragraph(body, styles["cell"])]],
        colWidths=[38 * mm, width - 38 * mm],
        hAlign="LEFT",
    )
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (0, 0), colors.HexColor("#E8D4AE")),
                ("BACKGROUND", (1, 0), (1, 0), PANEL),
                ("BOX", (0, 0), (-1, -1), 0.55, GOLD),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("LEFTPADDING", (0, 0), (-1, -1), 7),
                ("RIGHTPADDING", (0, 0), (-1, -1), 7),
                ("TOPPADDING", (0, 0), (-1, -1), 6),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
            ]
        )
    )
    return table


def footer(canvas, document) -> None:  # noqa: ANN001
    canvas.saveState()
    canvas.setStrokeColor(GOLD)
    canvas.setLineWidth(0.45)
    canvas.line(document.leftMargin, 12 * mm, A4[0] - document.rightMargin, 12 * mm)
    canvas.setFont("TetrisBlueprint" if FONT_PATH.is_file() else "Helvetica", 7)
    canvas.setFillColor(MUTED)
    canvas.drawString(document.leftMargin, 7.5 * mm, "TETRIS · Human Game Blueprint · Derived view, not canonical")
    canvas.drawRightString(A4[0] - document.rightMargin, 7.5 * mm, f"Page {document.page}")
    canvas.restoreState()


def build_story(styles: dict[str, ParagraphStyle], page_width: float) -> list:
    story: list = []
    story.append(Spacer(1, 13 * mm))
    story.append(paragraph("TETRIS HUMAN GAME BLUEPRINT", styles["title"]))
    story.append(paragraph("퍼즐 전술 전투 · 사람용 파생 기획서", styles["subtitle"]))
    story.append(
        paragraph(
            "<b>CANONICALITY:</b> 이 PDF는 현재 저장소 정본의 읽기 쉬운 파생 뷰입니다. 규칙, 수치, 승인과 구현 판단은 아래 출처 문서와 실제 Godot 소비 경로가 우선합니다.",
            styles["body"],
        )
    )
    story.append(Spacer(1, 3 * mm))
    story.append(paragraph("한 줄 경험", styles["heading"]))
    story.append(
        paragraph(
            "드롭 퍼즐과 체인 퍼즐을 오가며 <b>같은 적 행동 ETA</b> 안에서 콤보를 만들고, 전술 일시정지에서 현재 콤보에 맞는 기술 하나를 확인한 뒤 확정해 보스의 다음 위협에 대응한다.",
            styles["hero"],
        )
    )
    story.append(panel("플레이어 약속", "한 화면에서 무엇을 조작하는지, 지금 왜 급한지, 기술을 쓰면 무엇이 달라지는지를 끊김 없이 읽는다.", styles, page_width))
    story.append(Spacer(1, 5 * mm))
    story.append(paragraph("핵심 전투 표면", styles["heading"]))
    story.append(
        cell_table(
            [
                ["영역", "현재 역할", "읽는 순서"],
                ["좌측 50% · Puzzle", "LINE 또는 CHAIN 중 하나만 활성 workspace로 보여 주며, 하단에 조작 안내를 둔다.", "모드 선택 → 즉시 조작 → 결과/콤보 확인"],
                ["우측 상단 · Boss Stage", "Gatebreaker가 지배적인 무대 실루엣으로 위협을 전달한다. Vanguard는 이 구역에 배치하지 않는다.", "보스/현재 위협 → 다음 예고"],
                ["우측 중단 · SHARED ACTION ETA", "보스 행동 ETA와 플레이어 반응 가능 시간이 동일한 하나의 창임을 표시한다.", "CURRENT → 남은 ETA → NEXT"],
                ["우측 하단 · Skill", "ATK / DEF / SUP 카테고리 선택 → 현재 Combo에 맞는 한 기술 미리보기 → 명시적 CONFIRM.", "카테고리 → 효과/비용/불변 영역 → 확정"],
            ],
            [34 * mm, 87 * mm, 48 * mm],
            styles,
        )
    )
    story.append(paragraph("50 / 50 BATTLE SURFACE", styles["heading"]))
    story.append(
        cell_table(
            [
                ["LEFT · PUZZLE", "RIGHT · COMBAT"],
                ["Mode bar / Board / preview / controls / chain-lock choice", "Boss stage / shared timer / forecast / large Vanguard HUD portrait / skill overlay"],
                ["보드가 전투를 밀어내지 않으며, 안내는 하단에 둬 가로 면적을 확보한다.", "보스의 크기와 가시성을 우선하되, ETA와 기술 확정은 무대 위에 겹치지 않는다."],
            ],
            [84 * mm, 85 * mm],
            styles,
        )
    )
    story.append(paragraph("실시간 전투와 공유 행동 타이머", styles["heading"]))
    story.append(
        cell_table(
            [
                ["표시", "의미", "변하지 않는 원칙"],
                ["CURRENT THREAT", "지금 대응 중인 보스 행동과 잔여 ETA", "보스 시간이 곧 플레이어가 개입할 수 있는 시간이다."],
                ["SHARED ACTION ETA", "별도의 플레이어 턴 예산이 아니라 하나의 동일 창", "LINE, CHAIN, SKILL 모두 이 창을 읽고 활용한다."],
                ["TACTICAL PAUSE", "Skill을 열어 카테고리와 현재 콤보 기술을 검토하는 시간", "시뮬레이션과 보스 연출은 정지하고, Confirm 또는 Cancel로 재개한다."],
            ],
            [37 * mm, 65 * mm, 67 * mm],
            styles,
        )
    )
    story.append(paragraph("퍼즐 → 자원 → 기술 루프", styles["heading"]))
    story.append(
        cell_table(
            [
                ["단계", "LINE", "CHAIN", "전투 환류"],
                ["1. 조작", "낙하, 이동, 회전, HOLD, 하드 드롭", "인접 2칸 교환 후 직선 3+ 성립 확인", "진행 중 보스 ETA는 계속 읽힌다."],
                ["2. 성공", "라인 클리어와 테트리스로 MP/기회 회복", "성공 체인으로 COMBO 상승", "다음 기술의 해금 단계와 비용 판단이 생긴다."],
                ["3. 실패/선택", "보드 상태를 계속 개선", "불성립 교환은 취소 또는 MP를 지불해 유지", "실패도 선택으로 남기고, 숨은 자동 손실로 처리하지 않는다."],
                ["4. 확정", "카테고리를 선택", "현재 Combo 단계에 실제 존재하는 기술 하나를 표시", "Confirm 후 효과를 반영하고 공유 시간은 재개한다."],
            ],
            [25 * mm, 47 * mm, 48 * mm, 49 * mm],
            styles,
        )
    )
    story.append(paragraph("스킬 읽기와 확정 흐름", styles["heading"]))
    story.append(
        paragraph(
            "기술 UI의 C1-C8은 클릭 가능한 티어 벽이 아니라 <b>현재 콤보 단계와 해결된 효과를 읽는 표시</b>다. 사용자는 ATK, DEF, SUP 중 하나를 먼저 고르고, 현재 Combo에서 가능한 기술의 대상·효과·비용·변하지 않는 영역을 본 뒤 CONFIRM한다. 상위 콤보 기술이 없으면 정의된 fallback으로 내려가며, 변환된 콤보를 명시한다.",
            styles["body"],
        )
    )
    story.append(paragraph("첫 세션 흐름", styles["heading"]))
    story.append(
        cell_table(
            [
                ["1", "2", "3", "4", "5"],
                ["Briefing에서 목적과 조작을 짧게 읽는다.", "CURRENT THREAT와 ETA를 본다.", "LINE으로 자원을 회복한다.", "CHAIN 성공으로 콤보를 만든다.", "SKILL에서 미리보고 확정해 위협에 대응한다."],
            ],
            [33.8 * mm] * 5,
            styles,
        )
    )
    story.append(paragraph("현재 아트 소비 구조", styles["heading"]))
    art_cell: list = [paragraph("<b>TETRIS-IMG-037</b><br/>Gatebreaker Rift Core Combat Cutout v2<br/><br/>`CombatStage/GatebreakerReference`가 사용하는 현재 보스 무대 후보입니다.<br/><br/><b>상태</b><br/>USER_STANDING_APPROVED_RUNTIME_CANDIDATE<br/>PENDING_EXACT_HEAD_RENDER", styles["cell"])]
    if BOSS_ART_PATH.is_file():
        art = Image(str(BOSS_ART_PATH), width=46 * mm, height=69 * mm, kind="proportional")
        art_cell.append(art)
    visual_table = Table([[art_cell[0], art_cell[1] if len(art_cell) > 1 else ""]], colWidths=[106 * mm, 63 * mm], hAlign="LEFT")
    visual_table.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, -1), PANEL), ("BOX", (0, 0), (-1, -1), 0.55, GOLD), ("VALIGN", (0, 0), (-1, -1), "MIDDLE"), ("LEFTPADDING", (0, 0), (-1, -1), 9), ("RIGHTPADDING", (0, 0), (-1, -1), 9), ("TOPPADDING", (0, 0), (-1, -1), 8), ("BOTTOMPADDING", (0, 0), (-1, -1), 8)]))
    story.append(KeepTogether([visual_table, Spacer(1, 2 * mm)]))
    story.append(
        paragraph(
            "현 v2는 1024×1536 RGBA 투명 소스이며, Rift Core·ram-arm·chained flail이 남는 1024×1408 crop으로 CombatStage를 덮는다. 기존 `TETRIS-IMG-034`는 삭제하거나 덮어쓰지 않고, 정확한 원본 바이트를 유지한 rollback source로 남긴다. Vanguard는 ResourceFrame의 읽기 쉬운 얼굴/어깨 HUD portrait만 사용한다.",
            styles["body"],
        )
    )
    story.append(paragraph("검증 상태와 사람 검수", styles["heading"]))
    story.append(
        cell_table(
            [
                ["증거", "현재 상태", "아직 주장하지 않는 것"],
                ["정본/정적 계약", "구조화 문서, scene binding, PNG RGBA/alpha/hash, tooling tests", "실제 Godot 프레임의 시각 품질"],
                ["자동 테스트", "퍼즐·공유 ETA·스킬·체인·자산 소비 계약의 회귀 검사", "기기별 입력감, 성능, 접근성"],
                ["Runtime render", "PENDING_EXACT_HEAD_RENDER", "v2가 실제 실행 프레임에서 잘리지 않고 읽힌다는 PASS"],
                ["Human/UX", "PENDING", "보스 위압감, 보드/기술 가독성, 재미와 학습 흐름의 최종 승인"],
            ],
            [39 * mm, 65 * mm, 65 * mm],
            styles,
        )
    )
    story.append(paragraph("추가·수정·삭제 권장 사항", styles["heading"]))
    story.append(
        cell_table(
            [
                ["현재 상태", "권장 조치", "요청 이유", "기대 효과"],
                ["v2 보스는 scene binding 완료, exact-head render 미확보", "Tetris 전용 Godot 실행기에서 실제 창 캡처와 crop 확인", "정적 계약은 화면의 잘림·가독성을 보장하지 못한다.", "보스 위압감과 UI 경계의 실증"],
                ["보드·체인·기술은 단위/계약 검증 중심", "한 세션의 LINE→CHAIN→SKILL 실제 플레이 기록", "규칙 통과와 재미/학습성은 다르다.", "초기 이탈과 불명확한 콤보 원인 발견"],
                ["v1 Gatebreaker 파일은 복구용으로 보존", "사용처 0과 exact v2 render가 확인될 때까지 유지", "구형이라는 이유만으로 삭제하면 안전한 롤백을 잃는다.", "무손실 복구와 에셋 출처 추적"],
                ["사람용 PDF는 파생 뷰", "정본 규칙 변경 시 이 PDF를 재생성", "PDF를 독립 정본으로 취급하면 규칙이 이중화된다.", "기획/구현/검수의 단일 진실원 유지"],
            ],
            [39 * mm, 42 * mm, 43 * mm, 45 * mm],
            styles,
        )
    )
    story.append(paragraph("정본 출처", styles["heading"]))
    story.append(
        paragraph(
            "Project Master GDD · Production Realtime Combat Canon · Combo Resolved Skill Contract · Chain Combo MP Contract · Runtime Image Asset Consumer Contract · Visual Bible · First Session Onboarding Contract · Full Game Screen Surface Inventory · Approved Reference Manifest. 각 파일의 SHA-256은 함께 생성되는 manifest에서 고정한다.",
            styles["small"],
        )
    )
    return story


def build_pdf(output: Path) -> None:
    font_name = register_font()
    styles = styles_for(font_name)
    document = SimpleDocTemplate(
        str(output),
        pagesize=A4,
        rightMargin=20 * mm,
        leftMargin=20 * mm,
        topMargin=16 * mm,
        bottomMargin=19 * mm,
        title="TETRIS HUMAN GAME BLUEPRINT",
        author="Tetris repository derived-view generator",
        subject="Human-readable non-canonical project blueprint",
    )
    document.build(build_story(styles, A4[0] - document.leftMargin - document.rightMargin), onFirstPage=footer, onLaterPages=footer)


def write_json_atomically(path: Path, payload: dict) -> None:
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False, dir=path.parent, suffix=".tmp") as stream:
        json.dump(payload, stream, ensure_ascii=False, indent=2)
        stream.write("\n")
        temporary = Path(stream.name)
    temporary.replace(path)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=PDF_PATH)
    parser.add_argument("--manifest", type=Path, default=MANIFEST_PATH)
    arguments = parser.parse_args()

    output = arguments.output if arguments.output.is_absolute() else ROOT / arguments.output
    manifest = arguments.manifest if arguments.manifest.is_absolute() else ROOT / arguments.manifest
    output.parent.mkdir(parents=True, exist_ok=True)
    manifest.parent.mkdir(parents=True, exist_ok=True)
    sources = source_records()
    source_head = repository_head()

    with tempfile.NamedTemporaryFile(delete=False, dir=output.parent, suffix=".pdf") as stream:
        temporary_pdf = Path(stream.name)
    try:
        build_pdf(temporary_pdf)
        temporary_pdf.replace(output)
    finally:
        if temporary_pdf.exists():
            temporary_pdf.unlink()

    payload = {
        "schema_version": 1,
        "artifact_role": "HUMAN_GDD_PDF_DERIVED_VIEW",
        "canonicality": "NON_CANONICAL_DERIVED_VIEW",
        "source_git_head": source_head,
        "generation_utc": datetime.now(timezone.utc).isoformat(),
        "generator": "tools/build_human_game_blueprint_pdf.py",
        "pdf": {
            "path": output.relative_to(ROOT).as_posix(),
            "sha256": sha256(output),
        },
        "sources": sources,
        "evidence_ceiling": {
            "machine_contract": "document and static asset/scene facts only",
            "runtime_render": "PENDING_EXACT_HEAD_RENDER",
            "human_ux": "PENDING",
        },
    }
    write_json_atomically(manifest, payload)


if __name__ == "__main__":
    main()
