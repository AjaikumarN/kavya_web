# Workflow State Machines — Section 5
# Explicit state transitions. Invalid transitions rejected.

from app.models.postgres.intelligence import (
    TripWorkflowStatus as TW,
    FuelWorkflowStatus as FW,
    ExpenseWorkflowStatus as EW,
)

# ═══════════════════════════════════════════════════════════════
# Trip Workflow
# ═══════════════════════════════════════════════════════════════

TRIP_TRANSITIONS: dict[TW, list[TW]] = {
    TW.CREATED:              [TW.ASSIGNED, TW.CANCELLED, TW.SOS_ACTIVE],
    TW.ASSIGNED:             [TW.INSPECTION_PENDING, TW.CANCELLED, TW.SOS_ACTIVE],
    TW.INSPECTION_PENDING:   [TW.INSPECTION_COMPLETE, TW.CANCELLED, TW.SOS_ACTIVE],
    TW.INSPECTION_COMPLETE:  [TW.IN_TRANSIT, TW.CANCELLED, TW.SOS_ACTIVE],
    TW.IN_TRANSIT:           [TW.AT_DELIVERY, TW.CANCELLED, TW.SOS_ACTIVE],
    TW.AT_DELIVERY:          [TW.EPOD_PENDING, TW.CANCELLED, TW.SOS_ACTIVE],
    TW.EPOD_PENDING:         [TW.EPOD_COMPLETE, TW.CANCELLED, TW.SOS_ACTIVE],
    TW.EPOD_COMPLETE:        [TW.COMPLETED, TW.CANCELLED, TW.SOS_ACTIVE],
    TW.COMPLETED:            [TW.INVOICE_GENERATED, TW.CANCELLED],
    TW.INVOICE_GENERATED:    [TW.CLOSED, TW.CANCELLED],
    TW.CLOSED:               [],  # terminal
    TW.CANCELLED:            [],  # terminal
    TW.SOS_ACTIVE:           [TW.IN_TRANSIT, TW.AT_DELIVERY, TW.CANCELLED],  # can resume after SOS
}

# Who can trigger each transition
TRIP_TRANSITION_ROLES: dict[tuple[TW, TW], list[str]] = {
    (TW.CREATED, TW.ASSIGNED): ["admin", "manager"],
    (TW.ASSIGNED, TW.INSPECTION_PENDING): ["system"],
    (TW.INSPECTION_PENDING, TW.INSPECTION_COMPLETE): ["driver"],
    (TW.INSPECTION_COMPLETE, TW.IN_TRANSIT): ["driver"],
    (TW.IN_TRANSIT, TW.AT_DELIVERY): ["system"],  # geo-fence
    (TW.AT_DELIVERY, TW.EPOD_PENDING): ["system"],
    (TW.EPOD_PENDING, TW.EPOD_COMPLETE): ["driver"],
    (TW.EPOD_COMPLETE, TW.COMPLETED): ["system"],
    (TW.COMPLETED, TW.INVOICE_GENERATED): ["accountant", "system"],
    (TW.INVOICE_GENERATED, TW.CLOSED): ["admin", "accountant"],
}
# CANCELLED → any role=admin (special case handled in validate)


def validate_trip_transition(
    current: TW,
    target: TW,
    actor_role: str,
) -> tuple[bool, str]:
    """Validate whether a trip state transition is allowed.
    Returns (allowed, reason)."""
    if target == TW.CANCELLED:
        if actor_role == "admin":
            return True, ""
        return False, "Only admin can cancel a trip"

    if target == TW.SOS_ACTIVE:
        return True, ""  # anyone/system

    allowed_targets = TRIP_TRANSITIONS.get(current, [])
    if target not in allowed_targets:
        return False, f"Invalid transition: {current.value} → {target.value}"

    allowed_roles = TRIP_TRANSITION_ROLES.get((current, target), [])
    if allowed_roles and actor_role not in allowed_roles and "system" not in allowed_roles:
        return False, f"Role '{actor_role}' cannot trigger {current.value} → {target.value}"

    return True, ""


# ═══════════════════════════════════════════════════════════════
# Fuel Workflow
# ═══════════════════════════════════════════════════════════════

FUEL_TRANSITIONS: dict[FW, list[FW]] = {
    FW.LOG_ENTERED:            [FW.MISMATCH_CHECK_RUNNING],
    FW.MISMATCH_CHECK_RUNNING: [FW.MATCHED, FW.MISMATCH_FLAGGED],
    FW.MATCHED:                [],  # terminal
    FW.MISMATCH_FLAGGED:       [FW.UNDER_INVESTIGATION],
    FW.UNDER_INVESTIGATION:    [FW.EXPLAINED, FW.CONFIRMED_THEFT, FW.FALSE_POSITIVE],
    FW.EXPLAINED:              [],
    FW.CONFIRMED_THEFT:        [],
    FW.FALSE_POSITIVE:         [],
}


def validate_fuel_transition(current: FW, target: FW) -> tuple[bool, str]:
    allowed = FUEL_TRANSITIONS.get(current, [])
    if target not in allowed:
        return False, f"Invalid fuel transition: {current.value} → {target.value}"
    return True, ""


# ═══════════════════════════════════════════════════════════════
# Expense Workflow
# ═══════════════════════════════════════════════════════════════

EXPENSE_TRANSITIONS: dict[EW, list[EW]] = {
    EW.PHOTO_UPLOADED:           [EW.OCR_PROCESSING],
    EW.OCR_PROCESSING:           [EW.FRAUD_CHECK_RUNNING],
    EW.FRAUD_CHECK_RUNNING:      [EW.CLEAN, EW.FLAGGED],
    EW.CLEAN:                    [EW.AWAITING_APPROVAL],
    EW.FLAGGED:                  [EW.FLAGGED_AWAITING_REVIEW],
    EW.AWAITING_APPROVAL:        [EW.APPROVED, EW.REJECTED],
    EW.FLAGGED_AWAITING_REVIEW:  [EW.APPROVED, EW.REJECTED],
    EW.APPROVED:                 [EW.INCLUDED_IN_PAYROLL],
    EW.REJECTED:                 [],
    EW.INCLUDED_IN_PAYROLL:      [EW.PAID],
    EW.PAID:                     [],
}


def validate_expense_transition(current: EW, target: EW) -> tuple[bool, str]:
    allowed = EXPENSE_TRANSITIONS.get(current, [])
    if target not in allowed:
        return False, f"Invalid expense transition: {current.value} → {target.value}"
    return True, ""
