import type { Messages } from "./messages";

declare module "next-intl" {
  interface AppConfig {
    Messages: Messages;
  }
}
