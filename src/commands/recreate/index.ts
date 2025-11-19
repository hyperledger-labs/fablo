import { Command, Flags } from '@oclif/core';
import {spawn} from 'child_process';
import * as path from "path";


export default class Recreate extends Command {
  static override description = "Prunes and ups the network. Default config file path is '\$(pwd)/fablo-config.json' or '\$(pwd)/fablo-config.yaml'"
  static flags = {
    config: Flags.string({
      char: 'c',
      description: 'Path to fablo config file (JSON or YAML)',
      required: false,
      default: 'fablo-config.json',
    })
  }
  
  async run(): Promise<void> {
    const { flags } = await this.parse(Recreate)

    const shPath = path.resolve(__dirname, '../../../../fablo.sh')
    const args = ['recreate']
    if (flags.config) args.push(flags.config)

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
        this.log('\nNetwork recreate successfully!')
      } else {
        this.error(`\nFablo recreate failed with exit code: ${code}`)
      }
    })

    process.on('SIGINT', () => {
      child.kill('SIGINT')
      process.exit()
    })
  }




}
