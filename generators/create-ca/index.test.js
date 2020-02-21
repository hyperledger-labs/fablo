const helpers = require('yeoman-test');
const path = require('path');
const fs = require('fs');

describe(':create-ca', () => {
   it('should create CA', async () => {
    const dir = await helpers.run(__dirname)
      .withOptions({ orgKey: 'black-pearl' })
      .withPrompts({ prefix: 'aa', generate: true })
      .toPromise();

    console.log(dir);
const file =    fs.readFileSync(path.join(dir, '.yo-rc.json'));
console.log(file)
  });
});
