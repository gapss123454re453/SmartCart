-- AlterTable
ALTER TABLE "Product"
ADD COLUMN "packageQuantity" TEXT,
ADD COLUMN "originBase" TEXT,
ADD COLUMN "sourceUrl" TEXT;

-- CreateTable
CREATE TABLE "ProductRetailerEvidence" (
    "id" TEXT NOT NULL,
    "productBarcode" TEXT NOT NULL,
    "retailerName" TEXT NOT NULL,
    "region" TEXT,
    "linkMethod" TEXT,
    "confidence" TEXT,
    "sourceCatalogUrl" TEXT,
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ProductRetailerEvidence_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "ProductRetailerEvidence_productBarcode_retailerName_sourceCatalogUrl_key" ON "ProductRetailerEvidence"("productBarcode", "retailerName", "sourceCatalogUrl");

-- CreateIndex
CREATE INDEX "ProductRetailerEvidence_retailerName_idx" ON "ProductRetailerEvidence"("retailerName");

-- CreateIndex
CREATE INDEX "ProductRetailerEvidence_productBarcode_idx" ON "ProductRetailerEvidence"("productBarcode");

-- AddForeignKey
ALTER TABLE "ProductRetailerEvidence"
ADD CONSTRAINT "ProductRetailerEvidence_productBarcode_fkey"
FOREIGN KEY ("productBarcode") REFERENCES "Product"("barcode") ON DELETE CASCADE ON UPDATE CASCADE;
