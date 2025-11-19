import { Command } from '@oclif/core';
import { spawn } from 'child_process';
import * as path from "path";


export default class Stop extends Command {
  static override description = 'Stop the Hyperledger Fabric network for configuration in the current directory.';

  async run(): Promise<void> {

    const shPath = path.resolve(__dirname, '../../../../fablo.sh')
    const args = ['stop']

    this.log(`Starting network with: ${shPath} ${args.join(' ')}\n`)
    const child = spawn(shPath, args, {
      stdio: ['inherit', 'pipe', 'pipe'],
      shell: process.platform === 'win32' ? 'bash.exe' : true,
    })

    child.stdout?.on('data', (data) => {
      process.stdout.write(data.toString())
    })
    child.stderr?.on('data', (data) => {
      process.stderr.write(data.toString())
    })

    child.on('close', (code) => {
      if (code === 0) {
        this.log('\nNetwork Stop successfully!')
      } else {
        this.error(`\nFablo Stop failed with exit code: ${code}`)
      }
    })

    process.on('SIGINT', () => {
      child.kill('SIGINT')
      process.exit()
    })
  }




}
