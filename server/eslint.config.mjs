import love from 'eslint-config-love'

export default [
  {
    ...love,
    files: ['**/*.js', '**/*.ts'],
    ignores: [
      '**/build/**/*',
      '**/client-build/**/*',
      '**/.vscode/**/*',
      '**/node_modules/**/*'
    ],
    rules: {
      ...love.rules,
      'no-magic-numbers': 'off',
      '@typescript-eslint/no-magic-numbers': 'off',
      'eslint-comments/require-description': 'off',
      '@typescript-eslint/explicit-function-return-type': 'off',
      '@typescript-eslint/no-extraneous-class': 'off'
    }
  }
]
