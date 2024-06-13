class SessionStorage {}

export class InMemoryStorage extends SessionStorage {
  storage: object;

  constructor() {
    super();
    this.storage = {};
  }

  getItem(key: string) {
    return this.storage[key] || null;
  }
  removeItem(key: string) {
    delete this.storage[key];
  }
  setItem(key: string, value: any) {
    this.storage[key] = value;
  }
}
