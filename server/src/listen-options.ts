export function resolveListenHost(environment: NodeJS.ProcessEnv): string {
  const host = environment.HOST?.trim();
  return host && host.length > 0 ? host : '0.0.0.0';
}
