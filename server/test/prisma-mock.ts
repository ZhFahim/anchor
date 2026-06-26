type MockModel = Record<string, jest.Mock>;

export interface MockPrismaService {
  note: MockModel;
  notePin: MockModel;
  tag: MockModel;
  noteAttachment: MockModel;
  user: MockModel;
  $transaction: jest.Mock;
}

const model = (...methods: string[]): MockModel =>
  Object.fromEntries(methods.map((m) => [m, jest.fn()]));

// Reusable PrismaService double for service unit tests. Methods return
// undefined by default; set behaviour per test with mockResolvedValue etc.
export function createMockPrisma(): MockPrismaService {
  const prisma: MockPrismaService = {
    note: model('findMany', 'findUnique', 'create', 'update', 'updateMany'),
    notePin: model('create', 'delete', 'deleteMany'),
    tag: model('findMany', 'create', 'createMany'),
    noteAttachment: model('create', 'findMany', 'delete'),
    user: model('findUnique', 'findMany'),
    $transaction: jest.fn(),
  };

  prisma.$transaction.mockImplementation((arg: unknown) =>
    typeof arg === 'function'
      ? (arg as (tx: MockPrismaService) => unknown)(prisma)
      : Promise.all(arg as unknown[]),
  );

  return prisma;
}
