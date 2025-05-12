import parseFabloConfig from "./parseFabloConfig";

describe("parseFabloConfig", () => {
  it("should parse valid JSON config", () => {
    const jsonConfig = `{
      "global": {
        "fabricVersion": "2.5.9",
        "tls": false,
        "engine": "docker"
      },
      "orgs": [
        {
          "organization": {
            "name": "Org1",
            "domain": "org1.example.com"
          }
        }
      ]
    }`;

    const result = parseFabloConfig(jsonConfig);
    
    expect(result).toEqual({
      global: {
        fabricVersion: "2.5.9",
        tls: false,
        engine: "docker"
      },
      orgs: [
        {
          organization: {
            name: "Org1",
            domain: "org1.example.com"
          }
        }
      ]
    });
  });

  it("should parse valid YAML config", () => {
    const yamlConfig = `
      global:
        fabricVersion: "2.5.9"
        tls: false
        engine: docker
      orgs:
        - organization:
            name: Org1
            domain: org1.example.com
    `;

    const result = parseFabloConfig(yamlConfig);

    expect(result).toEqual({
      global: {
        fabricVersion: "2.5.9",
        tls: false,
        engine: "docker"
      },
      orgs: [
        {
          organization: {
            name: "Org1",
            domain: "org1.example.com"
          }
        }
      ]
    });
  });
});
