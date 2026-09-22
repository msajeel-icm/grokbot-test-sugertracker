from app.analyze import estimate_food, fraction_sugars, low_sugar_alternatives, match_hint


def test_fraction_sugar_is_one_third_and_one_half() -> None:
    portions = fraction_sugars(12)
    assert portions["1/3"] == 4
    assert portions["1/2"] == 6
    odd = fraction_sugars(10)
    assert odd["1/3"] == 3.33
    assert odd["1/2"] == 5


def test_hint_matches_catalog_without_substring_false_positives() -> None:
    assert match_hint("cookie").label == "chocolate chip cookie"
    assert match_hint("  CUCUMBER ").label == "cucumber"
    assert match_hint("pineapple") is None
    assert match_hint("apple").label == "apple"
    assert match_hint(None) is None
    assert match_hint("   ") is None


def test_same_image_bytes_always_pick_the_same_food() -> None:
    first = estimate_food(None, b"plate-photo-v1")
    second = estimate_food(None, b"plate-photo-v1")
    assert first == second
    hinted = estimate_food("chocolate chip cookie", b"plate-photo-v1")
    assert hinted.label == "chocolate chip cookie"
    assert hinted.sugar_g == 12


def test_unknown_hint_with_image_uses_the_image_hash() -> None:
    image = estimate_food(None, b"plate-photo-v1")
    both = estimate_food("not a real food", b"plate-photo-v1")
    assert both == image


def test_empty_input_uses_the_default_snack() -> None:
    food = estimate_food(None, None)
    assert food.label == "mixed snack"
    assert food.sugar_g == 18


def test_alternatives_include_at_least_two_low_sugar_foods() -> None:
    alternatives = low_sugar_alternatives("chocolate chip cookie")
    labels = [label for label, _sugar in alternatives]
    assert len(labels) >= 2
    assert "grilled chicken" in labels
    assert "cucumber" in labels
    assert all(sugar < 5 for _label, sugar in alternatives)

    without_chicken = [label for label, _sugar in low_sugar_alternatives("grilled chicken")]
    assert "grilled chicken" not in without_chicken
    assert len(without_chicken) >= 2
