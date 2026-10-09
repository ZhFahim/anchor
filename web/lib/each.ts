export async function eachLimited<T>(
  items: T[],
  run: (item: T) => Promise<unknown>,
  limit = 6,
): Promise<void> {
  const queue = [...items];
  const workers = Array.from(
    { length: Math.min(limit, queue.length) },
    async () => {
      for (let item = queue.shift(); item !== undefined; item = queue.shift())
        await run(item);
    },
  );
  await Promise.all(workers);
}
