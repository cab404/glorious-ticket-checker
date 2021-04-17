import typescript from '@rollup/plugin-typescript';
import resolve from '@rollup/plugin-node-resolve';
import copy from 'rollup-plugin-copy'

export default {
	plugins: [
        typescript(),
		resolve(),
		copy({
			targets: [
				{ src: "./node_modules/qr-scanner/qr-scanner-worker.min.js", dest: "../static/panel" }
			]
		})
	],
	input: "src/index.ts",
	output: {
		file: '../static/panel/bundle.js',
		format: 'es'
	}
};