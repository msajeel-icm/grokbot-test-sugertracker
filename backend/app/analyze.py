"""Deterministic food stub. Never calls a vision or nutrition API."""

import hashlib
import re
from dataclasses import dataclass

FRACTION_LABELS = ["1/3", "1/2"]
_FRACTION_FACTORS = (("1/3", 1 / 3), ("1/2", 1 / 2))


@dataclass(frozen=True)
class CatalogFood:
    label: str
    sugar_g: float
    kcal: float
    confidence: float
    keywords: tuple[str, ...] = ()


@dataclass(frozen=True)
class FoodEstimate:
    label: str
    sugar_g: float
    kcal: float
    confidence: float


# kcal is a typical serving estimate for display. It never feeds the sugar budget.
CATALOG: tuple[CatalogFood, ...] = (
    CatalogFood("glazed donut", 22.0, 269.0, 0.86, ("donut", "doughnut")),
    CatalogFood("chocolate chip cookie", 12.0, 160.0, 0.81, ("cookie",)),
    CatalogFood("cola", 39.0, 140.0, 0.93, ("cola", "soda")),
    CatalogFood("banana", 14.0, 105.0, 0.90, ("banana",)),
    CatalogFood("apple", 10.0, 95.0, 0.88, ("apple",)),
    CatalogFood("oatmeal", 1.0, 150.0, 0.84, ("oatmeal", "oats")),
    CatalogFood("grilled chicken", 0.0, 165.0, 0.92, ("chicken",)),
    CatalogFood("cucumber", 1.7, 16.0, 0.89, ("cucumber",)),
    CatalogFood("boiled eggs", 0.6, 155.0, 0.87, ("egg", "eggs")),
    CatalogFood("celery sticks", 1.2, 14.0, 0.83, ("celery",)),
)

DEFAULT_FOOD = CatalogFood("mixed snack", 18.0, 210.0, 0.50)

# Practical low-sugar swaps offered when a pick would blow the daily budget.
ALTERNATIVE_LABELS = (
    "grilled chicken",
    "cucumber",
    "boiled eggs",
    "celery sticks",
)


def scale_portions(amount: float) -> dict[str, float]:
    total = round(float(amount), 2)
    return {label: round(total * factor, 2) for label, factor in _FRACTION_FACTORS}


def fraction_sugars(sugar_g: float) -> dict[str, float]:
    return scale_portions(sugar_g)


def fraction_kcals(kcal: float) -> dict[str, float]:
    return scale_portions(kcal)


def match_hint(hint: str | None) -> CatalogFood | None:
    if hint is None:
        return None
    text = hint.strip().lower()
    if not text:
        return None
    for food in CATALOG:
        if text == food.label.lower():
            return food
    ranked = sorted(
        ((food, keyword) for food in CATALOG for keyword in food.keywords),
        key=lambda pair: len(pair[1]),
        reverse=True,
    )
    for food, keyword in ranked:
        if re.search(rf"(?<![a-z]){re.escape(keyword)}(?![a-z])", text):
            return food
    return None


def _from_bytes(data: bytes) -> CatalogFood:
    digest = hashlib.sha256(data).digest()
    index = int.from_bytes(digest[:8], "big") % len(CATALOG)
    return CATALOG[index]


def estimate_food(hint: str | None, image: bytes | None) -> FoodEstimate:
    """Pick a catalog food from a hint, else from a hash of the image bytes."""
    matched = match_hint(hint)
    if matched is not None:
        food = matched
    elif image:
        food = _from_bytes(image)
    elif hint and hint.strip():
        food = _from_bytes(hint.strip().lower().encode())
    else:
        food = DEFAULT_FOOD
    return FoodEstimate(
        label=food.label,
        sugar_g=round(float(food.sugar_g), 2),
        kcal=round(float(food.kcal), 2),
        confidence=round(float(food.confidence), 2),
    )


def low_sugar_alternatives(exclude_label: str) -> list[tuple[str, float, float]]:
    """Low-sugar swaps as (label, sugar_g, kcal). Sugar stays the budget gate."""
    excluded = exclude_label.strip().lower()
    by_label = {food.label.lower(): food for food in CATALOG}
    picked: list[tuple[str, float, float]] = []
    for label in ALTERNATIVE_LABELS:
        if label.lower() == excluded:
            continue
        food = by_label[label.lower()]
        picked.append((food.label, food.sugar_g, food.kcal))
    return picked
