import type { Prisma, PrismaClient } from "@prisma/client";

type Tx = Prisma.TransactionClient | PrismaClient;

export async function recalculateSessionTotals(db: Tx, sessionId: string) {
  const items = await db.shoppingItem.findMany({ where: { sessionId } });
  const totalAmount = items.reduce((sum, item) => sum + Number(item.totalPrice), 0);
  const expectedWeightGrams = items.reduce((sum, item) => sum + item.totalWeightGrams, 0);

  return db.shoppingSession.update({
    where: { id: sessionId },
    data: {
      totalAmount,
      expectedWeightGrams
    },
    include: {
      cart: true,
      items: { include: { product: true }, orderBy: { createdAt: "asc" } }
    }
  });
}
