def line_total(qty, unit_price, discount=0.0):
    return round(qty * unit_price * (1 - discount), 2)

def add_vat(amount, vat_rate=0.21):
    return round(amount * (1 + vat_rate), 2)

def revenue_by_channel(lines):
    result = {}
    for row in lines:
        ch = row.get("channel", "unknown")
        if not isinstance(ch, str) or ch.strip() == "":
            ch = "unknown"
        ch = ch.strip().lower()

        amount = line_total(row["qty"], row["unit_price"], row.get("discount", 0.0))
        result[ch] = result.get(ch, 0.0) + amount

    for k in result:
        result[k] = round(result[k], 2)
    return result