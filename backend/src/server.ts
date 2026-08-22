import { app } from "./app.js";
import { env } from "./services/env.js";

app.listen(env.port, () => {
  console.log(`SmartCart API running on http://localhost:${env.port}`);
});
