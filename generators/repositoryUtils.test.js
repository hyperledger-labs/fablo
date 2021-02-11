const assert = require('assert');
const repositoryUtils = require('../generators/repositoryUtils');

describe('versionSort', () => {
  it('should sort versions', () => {
    // Given
    const unsortedVersions = [
      '0.0.2',
      '0.0.2-unstable',
      '0.0.1',
      '0.1.11',
      '0.1.1',
      '0.1.1-unstable',
      '1.21.2',
    ];

    // When
    const sortedVersions = repositoryUtils.sortVersions(unsortedVersions);

    // Then
    const expectedVersions = [
      '1.21.2',
      '0.1.11',
      '0.1.1',
      '0.0.2',
      '0.0.1',
      '0.1.1-unstable',
      '0.0.2-unstable',
    ];
    assert.deepEqual(sortedVersions, expectedVersions);
  });
});
