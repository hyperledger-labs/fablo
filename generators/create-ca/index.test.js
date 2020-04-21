const helpers = require('yeoman-test');
const path = require('path');
const fs = require('fs');

describe(':create-ca', () => {
  it('should create CA with defaults', async () => {
    const dir = await helpers.run(__dirname).toPromise();

    const file = fs.readFileSync(path.join(dir, '.yo-rc.json'));

    expect(file.toString()).toMatchSnapshot();
  });

  it('should create CA with custom options', async () => {
    const dir = await helpers.run(__dirname)
      .withOptions({ orgKey: 'black-pearl' })
      .withPrompts({ prefix: 'black-org-', generate: true })
      .toPromise();

    const file = fs.readFileSync(path.join(dir, '.yo-rc.json'));

    expect(file.toString()).toMatchSnapshot();
  });
});
