import json
import re
import sys
from pathlib import Path

import pandas as pd


def clean(value, fallback=""):
    if pd.isna(value):
        return fallback
    return str(value).strip()


def infer_weight_grams(package_text, index):
    text = clean(package_text).lower().replace(",", ".")
    match = re.search(r"(\d+(?:\.\d+)?)\s*(kg|g|ml|l)\b", text)
    if match:
        number = float(match.group(1))
        unit = match.group(2)
        if unit == "kg":
            return max(1, round(number * 1000))
        if unit == "g":
            return max(1, round(number))
        if unit == "l":
            return max(1, round(number * 1000))
        if unit == "ml":
            return max(1, round(number))

    return 250 + (index % 18) * 50


def infer_demo_price(cents, index, category):
    if not pd.isna(cents):
        return round(float(cents) / 100, 2)

    base = 4.99 + (index % 35) * 0.83
    normalized_category = clean(category).lower()
    if "bebida" in normalized_category or "beverage" in normalized_category:
        base += 2
    if "latic" in normalized_category or "dair" in normalized_category:
        base += 4
    if "carne" in normalized_category or "meat" in normalized_category:
        base += 10
    return round(base, 2)


def build_products(source, output):
    dataframe = pd.read_csv(source, dtype={"gtin": "string"})

    products = []
    for index, row in dataframe.iterrows():
        barcode = clean(row.get("gtin"))
        name = clean(row.get("nome"), "Produto sem nome")
        if not barcode or not name:
            continue

        products.append(
            {
                "barcode": barcode,
                "name": name[:180],
                "brand": (clean(row.get("marca"), "Sem marca") or "Sem marca")[:100],
                "category": (clean(row.get("categoria"), "Geral") or "Geral")[:100],
                "price": infer_demo_price(row.get("preco_centavos"), index, row.get("categoria")),
                "weightGrams": infer_weight_grams(row.get("quantidade_embalagem"), index),
                "imageUrl": clean(row.get("imagem_url")) or None,
                "packageQuantity": clean(row.get("quantidade_embalagem")) or None,
                "originBase": clean(row.get("base_origem")) or clean(row.get("fonte")) or None,
                "sourceUrl": clean(row.get("fonte_gtin_url")) or clean(row.get("fonte_url")) or None,
            }
        )

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(products, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {len(products)} products to {output}")


def build_retailer_evidence(source, output):
    dataframe = pd.read_csv(source, dtype={"gtin": "string"})
    evidence = []
    for _, row in dataframe.iterrows():
        barcode = clean(row.get("gtin"))
        retailer_name = clean(row.get("rede"))
        if not barcode or not retailer_name:
            continue

        evidence.append(
            {
                "productBarcode": barcode,
                "retailerName": retailer_name,
                "region": clean(row.get("unidade_regiao")) or None,
                "linkMethod": clean(row.get("metodo_vinculo")) or None,
                "confidence": clean(row.get("confianca")) or None,
                "sourceCatalogUrl": clean(row.get("fonte_catalogo_url")) or None,
                "notes": clean(row.get("observacao")) or None,
            }
        )

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(evidence, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {len(evidence)} retailer evidence rows to {output}")


def main():
    if len(sys.argv) != 4:
        raise SystemExit(
            "Usage: build_imported_products.py products|retailers input.csv output.json"
        )

    mode = sys.argv[1]
    source = Path(sys.argv[2])
    output = Path(sys.argv[3])

    if mode == "products":
        build_products(source, output)
    elif mode == "retailers":
        build_retailer_evidence(source, output)
    else:
        raise SystemExit(f"Unknown mode: {mode}")


if __name__ == "__main__":
    main()
