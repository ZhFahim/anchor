import { Injectable } from '@nestjs/common';

export type NoteLockOwner = 'anchor' | 'homarr';

interface NoteLockEntry {
  noteId: string;
  owner: NoteLockOwner;
  ownerId: string;
  expiresAt: number;
}

export interface NoteLockResponse {
  status: 'acquired' | 'locked';
  lockedBy: NoteLockOwner;
  expiresAt: string;
}

export type NoteLockCheckResult =
  | { status: 'missing' }
  | { status: 'owned'; lock: NoteLockResponse }
  | { status: 'locked'; lock: NoteLockResponse };

@Injectable()
export class NoteLockService {
  private readonly locks = new Map<string, NoteLockEntry>();
  private readonly ttlMs = 2 * 60 * 1000;

  acquire(noteId: string, owner: NoteLockOwner, ownerId: string): NoteLockResponse {
    const existing = this.getActiveLock(noteId);
    if (existing && !this.isSameOwner(existing, owner, ownerId)) {
      return {
        status: 'locked',
        lockedBy: existing.owner,
        expiresAt: new Date(existing.expiresAt).toISOString(),
      };
    }

    const lock: NoteLockEntry = {
      noteId,
      owner,
      ownerId,
      expiresAt: Date.now() + this.ttlMs,
    };
    this.locks.set(noteId, lock);

    return {
      status: 'acquired',
      lockedBy: lock.owner,
      expiresAt: new Date(lock.expiresAt).toISOString(),
    };
  }

  check(noteId: string, owner: NoteLockOwner, ownerId: string): NoteLockCheckResult {
    const existing = this.getActiveLock(noteId);
    if (!existing) {
      return { status: 'missing' };
    }

    if (this.isSameOwner(existing, owner, ownerId)) {
      return {
        status: 'owned',
        lock: {
          status: 'acquired',
          lockedBy: existing.owner,
          expiresAt: new Date(existing.expiresAt).toISOString(),
        },
      };
    }

    return {
      status: 'locked',
      lock: {
        status: 'locked',
        lockedBy: existing.owner,
        expiresAt: new Date(existing.expiresAt).toISOString(),
      },
    };
  }

  release(noteId: string, owner: NoteLockOwner, ownerId: string): boolean {
    const existing = this.getActiveLock(noteId);
    if (!existing) return false;
    if (!this.isSameOwner(existing, owner, ownerId)) return false;

    this.locks.delete(noteId);
    return true;
  }

  private getActiveLock(noteId: string): NoteLockEntry | null {
    const existing = this.locks.get(noteId);
    if (!existing) return null;

    if (existing.expiresAt <= Date.now()) {
      this.locks.delete(noteId);
      return null;
    }

    return existing;
  }

  private isSameOwner(lock: NoteLockEntry, owner: NoteLockOwner, ownerId: string) {
    return lock.owner === owner && lock.ownerId === ownerId;
  }
}
