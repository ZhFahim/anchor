import type { AddressInfo } from 'net';
import { HttpClient, TestServer } from './http';
import { AttachmentsApi } from './api/attachments.api';
import { ExportApi } from './api/export.api';
import { LinksApi } from './api/links.api';
import { NotesApi } from './api/notes.api';
import { RevisionsApi } from './api/revisions.api';
import { SharesApi } from './api/shares.api';
import { SyncApi } from './api/sync.api';
import { TagsApi } from './api/tags.api';
import { openSyncEventStream, SyncEventStream } from './api/events.api';

export interface TestUser {
  id: string;
  email: string;
  name: string;
  token: string;
}

/** A registered user together with the API they can drive. */
export class Actor implements TestUser {
  readonly notes: NotesApi;
  readonly tags: TagsApi;
  readonly shares: SharesApi;
  readonly links: LinksApi;
  readonly attachments: AttachmentsApi;
  readonly revisions: RevisionsApi;
  readonly export: ExportApi;
  readonly sync: SyncApi;
  readonly http: HttpClient;

  constructor(
    server: TestServer,
    private readonly address: AddressInfo,
    private readonly user: TestUser,
    private readonly trackStream: (stream: SyncEventStream) => void,
  ) {
    this.http = new HttpClient(server, user.token);
    this.notes = new NotesApi(this.http);
    this.tags = new TagsApi(this.http);
    this.shares = new SharesApi(this.http);
    this.links = new LinksApi(this.http);
    this.attachments = new AttachmentsApi(this.http);
    this.revisions = new RevisionsApi(this.http);
    this.export = new ExportApi(this.http);
    this.sync = new SyncApi(this.http);
  }

  get id(): string {
    return this.user.id;
  }

  get email(): string {
    return this.user.email;
  }

  get name(): string {
    return this.user.name;
  }

  get token(): string {
    return this.user.token;
  }

  get auth(): { Authorization: string } {
    return this.http.headers;
  }

  /** Closed for you by `ctx.closeEventStreams()`. */
  async openEventStream(): Promise<SyncEventStream> {
    const stream = await openSyncEventStream(this.address, this.user.token);
    this.trackStream(stream);
    return stream;
  }
}
