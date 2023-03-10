import { nodeResolve } from '@rollup/plugin-node-resolve';
import commonjs from '@rollup/plugin-commonjs';
import esbuild from 'rollup-plugin-esbuild';
import { defineConfig } from 'rollup';

function addWindowDeclaration() {
  return {
    name: 'window-is-this',
    generateBundle: (_, bundle) => {
      for (const file in bundle) {
        bundle[file].code += 'const window = this;';
      }
    }
  }
}

export default defineConfig({
  input: 'devtools.js',
  output: [
    {
      file: 'resources/devtools.js',
      format: 'cjs',
      strict: false
    },
  ],
  plugins: [
    nodeResolve(),
    commonjs(),
    esbuild({ minify: true, target: 'ES2019' }),
    addWindowDeclaration()
  ]
});