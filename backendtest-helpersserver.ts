import type { Server } from 'http';

/**
 * Mock de servidor HTTP para tests
 */
export class MockServer {
  private server: Server | null = null;

  async start(port: number, handler: any): Promise<string> {
    return new Promise((resolve, reject) => {
      try {
        this.server = handler.listen(port, () => {
          resolve(`http://localhost:${port}`);
        });
      } catch (error) {
        reject(error);
      }
    });
  }

  async stop(): Promise<void> {
    return new Promise((resolve, reject) => {
      if (!this.server) {
        resolve();
        return;
      }
      
      this.server.close((err) => {
        if (err) reject(err);
        else resolve();
      });
    });
  }
}

/**
 * Mock de cliente HTTP para tests
 */
export class MockHTTPClient {
  private responses: Map<string, any> = new Map();

  setResponse(endpoint: string, response: any): void {
    this.responses.set(endpoint, response);
  }

  async get(endpoint: string): Promise<any> {
    const response = this.responses.get(endpoint);
    if (!response) {
      throw new Error(`No mock response for ${endpoint}`);
    }
    return response;
  }

  async post(endpoint: string, data: any): Promise<any> {
    const response = this.responses.get(endpoint);
    if (!response) {
      throw new Error(`No mock response for ${endpoint}`);
    }
    return response;
  }

  clear(): void {
    this.responses.clear();
  }
}
