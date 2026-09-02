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
    PageBreak,
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
VANGUARD_ART_PATH = ROOT / "assets" / "production" / "characters" / "vanguard_combat_cutout_v1.png"

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
        "eyebrow": ParagraphStyle(
            "BlueprintEyebrow",
            parent=base["Normal"],
            fontName=font_name,
            fontSize=8.2,
            leading=10,
            textColor=GOLD,
            spaceAfter=4,
        ),
        "display": ParagraphStyle(
            "BlueprintDisplay",
            parent=base["Title"],
            fontName=font_name,
            fontSize=22,
            leading=28,
            textColor=INK,
            spaceAfter=8,
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
        "card_title": ParagraphStyle(
            "BlueprintCardTitle",
            parent=base["Heading3"],
            fontName=font_name,
            fontSize=10.2,
            leading=13,
            textColor=INK,
            spaceAfter=3,
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


def card(
    kicker: str,
    title: str,
    body: str,
    styles: dict[str, ParagraphStyle],
    width: float,
    accent: colors.Color = GOLD,
) -> Table:
    content = [
        paragraph(f"<font color='#765537'><b>{kicker}</b></font>", styles["small"]),
        paragraph(title, styles["card_title"]),
        paragraph(body, styles["cell"]),
    ]
    table = Table([[content]], colWidths=[width], hAlign="LEFT")
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), PANEL),
                ("BOX", (0, 0), (-1, -1), 0.7, accent),
                ("LINEABOVE", (0, 0), (-1, 0), 3, accent),
                ("LEFTPADDING", (0, 0), (-1, -1), 8),
                ("RIGHTPADDING", (0, 0), (-1, -1), 8),
                ("TOPPADDING", (0, 0), (-1, -1), 8),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ]
        )
    )
    return table


def embedded_project_assets() -> list[dict[str, str]]:
    """Register the existing project identities reused in the PDF without promoting it to runtime proof."""
    required_assets = [
        (
            "TETRIS-IMG-033",
            VANGUARD_ART_PATH,
            "Vanguard HUD portrait source; battle scene consumer remains ResourceRow/VanguardPortrait.",
        ),
        (
            "TETRIS-IMG-037",
            BOSS_ART_PATH,
            "Gatebreaker CombatStage source; battle scene consumer remains CombatStage/GatebreakerReference.",
        ),
    ]
    records = []
    for asset_id, path, source_role in required_assets:
        if not path.is_file():
            raise FileNotFoundError(f"required project identity asset is missing: {path}")
        records.append(
            {
                "asset_id": asset_id,
                "path": path.relative_to(ROOT).as_posix(),
                "sha256": sha256(path),
                "consumer": "TETRIS_HUMAN_GAME_BLUEPRINT.pdf · current-screen identity plate",
                "source_role": source_role,
                "evidence_boundary": "Reused project asset in a derived PDF; it does not establish an exact-head render or Human/UX evidence.",
            }
        )
    return records


def current_screen_identity_plate(styles: dict[str, ParagraphStyle], page_width: float) -> Table:
    """Show the existing screen hierarchy without inventing a synthetic battle screenshot."""
    left_width = 87 * mm
    right_width = page_width - left_width
    puzzle_column = [
        paragraph("<b>CURRENT-SCREEN IDENTITY PLATE</b>", styles["eyebrow"]),
        paragraph("NO SYNTHETIC BATTLE SCREEN", styles["card_title"]),
        paragraph(
            "이 표지는 새 전투 화면을 그려 넣지 않는다. 현재 Godot 전투 화면이 가진 <b>50 / 50</b> 정보 우선순위와 실제 프로젝트 캐릭터 자산만 재사용해, 사람이 화면을 읽는 순서를 설명한다.",
            styles["cell"],
        ),
        Spacer(1, 4 * mm),
        card("LEFT 50%", "하나의 큰 Puzzle Surface", "LINE 또는 CHAIN 하나만 크게 보인다. 조작 안내는 보드의 가로 폭을 빼앗지 않는 하단 영역에 둔다.", styles, left_width - 14 * mm, BLUE),
        Spacer(1, 3 * mm),
        card("SHARED ACTION ETA", "보스 행동 = 플레이어 반응 창", "CURRENT THREAT·ETA·NEXT가 보스와 플레이어가 공유하는 같은 실시간 창을 읽게 한다. 별도 플레이어 턴 타이머는 만들지 않는다.", styles, left_width - 14 * mm, RED),
        Spacer(1, 4 * mm),
        paragraph("<b>Vanguard HUD portrait · TETRIS-IMG-033</b>", styles["small"]),
        Image(str(VANGUARD_ART_PATH), width=27 * mm, height=34 * mm, kind="proportional"),
        paragraph("Vanguard는 보스 무대가 아닌 HP / MP / Combo 옆의 읽기 쉬운 portrait 역할만 유지한다.", styles["small"]),
    ]
    boss_column = [
        paragraph("<font color='#F3E7CE'><b>RIGHT 50% · COMBAT STAGE</b></font>", styles["small"]),
        paragraph("<font color='#F3E7CE'><b>Gatebreaker dominates the threat stage</b></font>", styles["cell"]),
        Spacer(1, 2 * mm),
        Image(str(BOSS_ART_PATH), width=right_width - 12 * mm, height=86 * mm, kind="proportional"),
        Spacer(1, 2 * mm),
        paragraph("<font color='#F3E7CE'>TETRIS-IMG-037 · CombatStage / GatebreakerReference</font>", styles["small"]),
        paragraph("<font color='#F3E7CE'>보스 이미지는 무대를 지배하지만, ETA·자원·Skill surface를 덮지 않는다.</font>", styles["small"]),
    ]
    plate = Table([[puzzle_column, boss_column]], colWidths=[left_width, right_width], hAlign="LEFT")
    plate.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (0, 0), PANEL),
                ("BACKGROUND", (1, 0), (1, 0), INK),
                ("BOX", (0, 0), (-1, -1), 0.85, GOLD),
                ("LINEBEFORE", (1, 0), (1, 0), 0.55, GOLD),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 7 * mm),
                ("RIGHTPADDING", (0, 0), (-1, -1), 7 * mm),
                ("TOPPADDING", (0, 0), (-1, -1), 6 * mm),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 6 * mm),
            ]
        )
    )
    return plate


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
    half_width = (page_width - 4 * mm) / 2
    third_width = (page_width - 8 * mm) / 3

    story.append(Spacer(1, 5 * mm))
    story.append(paragraph("VISUAL PRODUCTION BLUEPRINT · DERIVED VIEW", styles["eyebrow"]))
    story.append(paragraph("TETRIS HUMAN GAME BLUEPRINT", styles["display"]))
    story.append(paragraph("퍼즐 전술 전투 · 사람용 파생 기획서", styles["subtitle"]))
    story.append(
        paragraph(
            "<b>한 줄 경험.</b> 드롭 퍼즐과 체인 퍼즐을 오가며 <b>같은 적 행동 ETA</b> 안에서 콤보를 만들고, 전술 일시정지에서 현재 콤보에 맞는 기술 하나를 확인한 뒤 확정해 보스의 다음 위협에 대응한다.",
            styles["hero"],
        )
    )
    story.append(current_screen_identity_plate(styles, page_width))
    story.append(Spacer(1, 4 * mm))
    story.append(
        Table(
            [[
                card("THE PROMISE", "한 화면 안에서 즉시 읽는다", "무엇을 조작하는지, 왜 지금 급한지, 기술을 쓰면 무엇이 달라지는지가 끊기지 않는다.", styles, half_width, BLUE),
                card("CANONICALITY", "PDF는 설명용 파생 뷰", "규칙·수치·승인·구현 판단은 저장소 정본과 실제 Godot 소비 경로가 우선한다.", styles, half_width, GOLD),
            ]],
            colWidths=[half_width, half_width + 4 * mm],
            hAlign="LEFT",
            style=[("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 0), ("RIGHTPADDING", (0, 0), (-1, -1), 0)],
        )
    )

    story.append(PageBreak())
    story.append(paragraph("01 · BATTLE SURFACE MAP", styles["eyebrow"]))
    story.append(paragraph("보드와 전투는 같은 비중, 하나의 위협 창", styles["display"]))
    story.append(
        paragraph(
            "좌측은 하나의 큰 Puzzle Surface, 우측은 보스 무대·위협·자원·스킬 표면이다. 비율은 약 <b>50 / 50</b>이며, 보스 행동 ETA와 플레이어 반응 가능 시간은 분리된 턴 예산이 아닌 같은 하나의 창이다.",
            styles["body"],
        )
    )
    story.append(Spacer(1, 4 * mm))
    story.append(
        Table(
            [[
                card("LEFT 50% · PUZZLE", "LINE 또는 CHAIN", "한 번에 하나의 전체 workspace만 활성화한다. 보드가 전투를 밀어내지 않게 조작 안내는 하단에 둔다.", styles, half_width, BLUE),
                card("RIGHT 50% · COMBAT", "Boss Stage + Threat + Skill", "Gatebreaker가 전투 무대를 지배한다. Vanguard는 보스 영역이 아니라 읽기 쉬운 HUD portrait로만 남긴다.", styles, half_width, VIOLET),
            ]],
            colWidths=[half_width, half_width + 4 * mm],
            hAlign="LEFT",
            style=[("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 0), ("RIGHTPADDING", (0, 0), (-1, -1), 0)],
        )
    )
    story.append(Spacer(1, 5 * mm))
    story.append(card("SHARED ACTION ETA", "적 행동 시간 = 플레이어 반응 시간", "CURRENT THREAT → 남은 ETA → NEXT를 읽는다. 플레이어 턴 게이지를 새로 만들지 않는다. LINE, CHAIN, SKILL 모두 같은 행동 창을 활용한다.", styles, page_width, RED))
    story.append(Spacer(1, 6 * mm))
    story.append(paragraph("읽는 순서", styles["heading"]))
    story.append(
        cell_table(
            [
                ["1 · THREAT", "2 · CHOOSE", "3 · ACT", "4 · CONFIRM"],
                ["보스/현재 위협과 ETA", "LINE 또는 CHAIN", "결과·MP·Combo", "카테고리 기술 미리보기"],
            ],
            [page_width / 4] * 4,
            styles,
        )
    )
    story.append(Spacer(1, 4 * mm))
    story.append(panel("고정 경계", "보스 무대에는 보스만 둔다. ETA·기술 확정·HUD는 무대를 가리지 않는 별도 표면에 놓고, 보드는 왼쪽의 가로 폭을 끝까지 확보한다.", styles, page_width))
    story.append(Spacer(1, 7 * mm))
    story.append(paragraph("이 표면에서 확인한 것과 아직 남은 것", styles["heading"]))
    story.append(
        cell_table(
            [
                ["현재 확인", "아직 주장하지 않는 것"],
                ["50 / 50 화면 경계·공유 ETA·보스/플레이어 배치 계약", "실제 Godot 프레임의 크롭·가독성·보스 위압감"],
                ["파생 PDF의 입력 SHA-256과 재사용 프로젝트 자산 provenance", "Human/UX에서의 재미·학습 흐름 최종 승인"],
            ],
            [page_width / 2] * 2,
            styles,
        )
    )

    story.append(PageBreak())
    story.append(paragraph("02 · PLAYER LOOP", styles["eyebrow"]))
    story.append(paragraph("퍼즐에서 만든 기회가 전술 선택으로 돌아온다", styles["display"]))
    story.append(
        Table(
            [[
                card("01", "위협을 읽는다", "CURRENT THREAT와 ETA를 읽고, 보드 전환이 필요한지 판단한다.", styles, third_width, RED),
                card("02", "LINE 또는 CHAIN", "LINE은 MP를, CHAIN은 Combo와 CHAIN MP 회복 기회를 만든다.", styles, third_width, BLUE),
                card("03", "전술 일시정지", "ATK / DEF / SUP 중 하나를 보고 현재 Combo에 맞는 기술 하나를 명시적으로 CONFIRM한다.", styles, third_width, VIOLET),
            ]],
            colWidths=[third_width, third_width + 4 * mm, third_width + 4 * mm],
            hAlign="LEFT",
            style=[("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 0), ("RIGHTPADDING", (0, 0), (-1, -1), 0)],
        )
    )
    story.append(Spacer(1, 7 * mm))
    story.append(paragraph("두 퍼즐 workspace의 역할", styles["heading"]))
    story.append(
        Table(
            [[
                card("LINE", "MP의 주 공급원", "낙하·이동·회전·HOLD·하드 드롭으로 라인을 정리한다. Single / Double / Triple / Four는 승인된 초기 MP 기회를 만든다.", styles, half_width, BLUE),
                card("CHAIN", "Combo의 주 공급원", "인접 2칸을 교환해 직선 3+를 만든다. 성공 wave는 Combo +1 후 정해진 규칙으로 MP를 회복한다. 실패 교환은 취소하거나 1 MP lock으로 유지한다.", styles, half_width, VIOLET),
            ]],
            colWidths=[half_width, half_width + 4 * mm],
            hAlign="LEFT",
            style=[("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 0), ("RIGHTPADDING", (0, 0), (-1, -1), 0)],
        )
    )
    story.append(Spacer(1, 7 * mm))
    story.append(card("SKILL READOUT", "ATK / DEF / SUP → 현재 Combo 미리보기 → CONFIRM", "C1-C8은 클릭 가능한 티어 벽이 아니라 현재 Combo 단계와 해결된 효과를 읽는 표시다. 카테고리 선택은 소비가 아니며, Confirm에서만 비용·효과·5 MP당 Combo fallback 변환을 원자적으로 반영한다. Cancel 또는 성공적인 Use는 정확히 멈춘 시간에서 다시 시작한다.", styles, page_width, GOLD))
    story.append(Spacer(1, 6 * mm))
    story.append(panel("첫 세션", "Briefing → CURRENT THREAT/ETA → LINE으로 MP 확보 → CHAIN으로 Combo → SKILL 미리보기·확정. 규칙의 설명 순서가 아니라 플레이어가 실제로 읽고 행동하는 순서다.", styles, page_width))

    story.append(PageBreak())
    story.append(paragraph("03 · PRODUCTION & PROOF", styles["eyebrow"]))
    story.append(paragraph("보여 주는 것과 아직 검증하지 않은 것을 분리한다", styles["display"]))
    art_cell: list = [paragraph("<b>TETRIS-IMG-037</b><br/>Gatebreaker Rift Core Combat Cutout v2<br/><br/>`CombatStage/GatebreakerReference`가 사용하는 현재 보스 무대 후보입니다.<br/><br/><b>상태</b><br/>USER_STANDING_APPROVED_RUNTIME_CANDIDATE<br/>PENDING_EXACT_HEAD_RENDER", styles["cell"])]
    if BOSS_ART_PATH.is_file():
        art_cell.append(Image(str(BOSS_ART_PATH), width=42 * mm, height=56 * mm, kind="proportional"))
    visual_table = Table([[art_cell[0], art_cell[1] if len(art_cell) > 1 else ""]], colWidths=[104 * mm, 65 * mm], hAlign="LEFT")
    visual_table.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, -1), PANEL), ("BOX", (0, 0), (-1, -1), 0.7, GOLD), ("VALIGN", (0, 0), (-1, -1), "MIDDLE"), ("LEFTPADDING", (0, 0), (-1, -1), 9), ("RIGHTPADDING", (0, 0), (-1, -1), 9), ("TOPPADDING", (0, 0), (-1, -1), 8), ("BOTTOMPADDING", (0, 0), (-1, -1), 8)]))
    story.append(KeepTogether([visual_table, Spacer(1, 3 * mm)]))
    story.append(paragraph("v2는 1024×1536 RGBA 투명 소스이며, Rift Core·ram-arm·chained flail이 남는 1024×1408 crop으로 CombatStage를 덮는다. v1 `TETRIS-IMG-034`는 덮어쓰지 않은 rollback source로 유지한다.", styles["body"]))
    story.append(paragraph("추가·수정·삭제 권장 사항", styles["heading"]))
    story.append(
        cell_table(
            [
                ["현재 상태", "권장 조치", "요청 이유", "기대 효과"],
                ["v2 보스는 scene binding 완료, exact-head render 미확보", "Tetris 전용 Godot 실행기에서 실제 창 캡처와 crop 확인", "정적 계약은 화면의 잘림·가독성을 보장하지 못한다.", "보스 위압감과 UI 경계의 실증"],
                ["보드·체인·기술은 단위/계약 검증 중심", "한 세션의 LINE→CHAIN→SKILL 실제 플레이 기록", "규칙 통과와 재미/학습성은 다르다.", "초기 이탈과 불명확한 Combo 원인 발견"],
                ["v1 Gatebreaker는 rollback source", "사용처 0과 exact v2 render가 확인될 때까지 유지", "구형이라는 이유만으로 삭제하면 안전한 복구를 잃는다.", "무손실 복구와 에셋 출처 추적"],
                ["사람용 PDF는 파생 뷰", "정본 규칙 변경 시 이 PDF를 재생성", "PDF가 독립 정본이 되면 규칙이 이중화된다.", "기획·구현·검수의 단일 진실원 유지"],
            ],
            [39 * mm, 42 * mm, 43 * mm, 45 * mm],
            styles,
        )
    )
    story.append(Spacer(1, 5 * mm))
    story.append(paragraph("정본 출처", styles["heading"]))
    story.append(paragraph("Project Master GDD · Production Realtime Combat Canon · Combo Resolved Skill Contract · Chain Combo MP Contract · Runtime Image Asset Consumer Contract · Visual Bible · First Session Onboarding Contract · Full Game Screen Surface Inventory · Approved Reference Manifest. 각 파일의 SHA-256과 재사용 프로젝트 자산 hash는 함께 생성되는 manifest에서 고정한다.", styles["small"]))
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
    visual_assets = embedded_project_assets()
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
        "planning_visual_assets": [],
        "cover_visual_policy": "REUSE_CURRENT_RUNTIME_IDENTITY_ASSETS_NO_SYNTHETIC_SCREEN_RECOMPOSITION",
        "embedded_project_assets": visual_assets,
        "evidence_ceiling": {
            "machine_contract": "document and static asset/scene facts only",
            "runtime_render": "PENDING_EXACT_HEAD_RENDER",
            "human_ux": "PENDING",
        },
    }
    write_json_atomically(manifest, payload)


if __name__ == "__main__":
    main()
