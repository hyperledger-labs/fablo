module.exports = {
  env: {
    browser: true,
    commonjs: true,
    es6: true,
    "jest/globals": true
  },
  extends: [
    'airbnb-base',
  ],
  globals: {
    Atomics: 'readonly',
    SharedArrayBuffer: 'readonly',
  },
  parserOptions: {
    ecmaVersion: 2018,
  },
  rules: {
<<<<<<< HEAD
=======
    'class-methods-use-this': 'off',
    'no-underscore-dangle': 'off',
>>>>>>> minor cleanup in generators
  },
  plugins: ['jest']
};
