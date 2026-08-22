import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();

const products = [
  ["7891000000010", "Arroz Tipo 1 5kg", "Campo Bom", "Mercearia", 25.9, 5120],
  ["7891000000027", "Feijao Carioca 1kg", "Grao Nobre", "Mercearia", 8.5, 1020],
  ["7891000000034", "Macarrao Espaguete 500g", "Bella Massa", "Mercearia", 4.2, 510],
  ["7891000000041", "Molho de Tomate 340g", "Sabor Casa", "Mercearia", 3.69, 360],
  ["7891000000058", "Cafe Torrado 500g", "Serra Alta", "Bebidas", 18.9, 515],
  ["7891000000065", "Acucar Refinado 1kg", "Doce Vale", "Mercearia", 4.99, 1015],
  ["7891000000072", "Sal Refinado 1kg", "Cristalino", "Mercearia", 2.89, 1010],
  ["7891000000089", "Oleo de Soja 900ml", "Sol Dourado", "Mercearia", 6.99, 880],
  ["7891000000096", "Leite Integral 1L", "Fazenda Sul", "Laticinios", 5.19, 1030],
  ["7891000000102", "Iogurte Natural 170g", "Fazenda Sul", "Laticinios", 2.99, 185],
  ["7891000000119", "Queijo Mussarela 400g", "Bom Leite", "Laticinios", 19.9, 420],
  ["7891000000126", "Presunto Fatiado 200g", "Frios Max", "Frios", 9.8, 215],
  ["7891000000133", "Pao de Forma 500g", "Pao & Cia", "Padaria", 8.99, 520],
  ["7891000000140", "Biscoito Cream Cracker 350g", "Croccare", "Biscoitos", 5.49, 370],
  ["7891000000157", "Chocolate ao Leite 90g", "Cacau Feliz", "Doces", 4.79, 98],
  ["7891000000164", "Refrigerante Cola 2L", "Pop Cola", "Bebidas", 8.49, 2070],
  ["7891000000171", "Agua Mineral 1.5L", "Fonte Azul", "Bebidas", 3.29, 1530],
  ["7891000000188", "Suco de Uva 1L", "Pomare", "Bebidas", 9.9, 1060],
  ["7891000000195", "Detergente 500ml", "BrilhaMais", "Limpeza", 2.39, 535],
  ["7891000000201", "Sabao em Po 1kg", "LavaBem", "Limpeza", 12.9, 1040],
  ["7891000000218", "Amaciante 2L", "Maciez", "Limpeza", 11.5, 2075],
  ["7891000000225", "Papel Higienico 12 rolos", "SuaveLar", "Higiene", 18.99, 980],
  ["7891000000232", "Shampoo 350ml", "Cabelo Vivo", "Higiene", 14.9, 380],
  ["7891000000249", "Sabonete 90g", "Floratta", "Higiene", 2.49, 95],
  ["7891000000256", "Creme Dental 90g", "Sorriso Bom", "Higiene", 4.5, 105],
  ["7891000000263", "Banana Prata 1kg", "Hortifruti", "Hortifruti", 6.99, 1000],
  ["7891000000270", "Tomate 1kg", "Hortifruti", "Hortifruti", 7.49, 1000],
  ["7891000000287", "Batata 1kg", "Hortifruti", "Hortifruti", 5.99, 1000],
  ["7891000000294", "Frango Congelado 1kg", "Ave Boa", "Carnes", 13.9, 1030],
  ["7891000000300", "Carne Moida 500g", "Boi Nobre", "Carnes", 19.99, 520]
] as const;

async function main() {
  await prisma.user.upsert({
    where: { email: "demo@smartcart.local" },
    update: {},
    create: {
      name: "Cliente Demo",
      email: "demo@smartcart.local",
      passwordHash: await bcrypt.hash("123456", 12)
    }
  });

  for (const [barcode, name, brand, category, price, weightGrams] of products) {
    await prisma.product.upsert({
      where: { barcode },
      update: { name, brand, category, price, weightGrams, active: true },
      create: {
        barcode,
        name,
        brand,
        category,
        price,
        weightGrams,
        imageUrl: `https://placehold.co/300x300/png?text=${encodeURIComponent(name)}`
      }
    });
  }

  for (let index = 1; index <= 5; index += 1) {
    const code = `CART-${String(index).padStart(6, "0")}`;
    await prisma.cart.upsert({
      where: { code },
      update: { status: "AVAILABLE" },
      create: { code, status: "AVAILABLE" }
    });
  }
}

main()
  .then(async () => prisma.$disconnect())
  .catch(async (error) => {
    console.error(error);
    await prisma.$disconnect();
    process.exit(1);
  });
