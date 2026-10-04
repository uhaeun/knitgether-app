// Offline check: no server, account, or database is used.
const { createRequire } = require('node:module');
const path = require('node:path');
const fs = require('node:fs');
const vm = require('node:vm');
const { randomUUID } = require('node:crypto');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const serverRequire = createRequire(path.join(root, 'server/package.json'));
serverRequire('ts-node').register({ project: path.join(root, 'server/tsconfig.json') });
serverRequire('reflect-metadata');
const { plainToInstance } = serverRequire('class-transformer');
const { validateSync } = serverRequire('class-validator');
const { SaveProjectDto } = serverRequire('./src/projects/project-save.dto.ts');
const collection = JSON.parse(fs.readFileSync(path.join(root, 'docs/qa/postman/knitgether-local.postman_collection.json')));
const item = collection.item.find(item => item.name === 'Projects Create');
function generate() {
  const values = new Map();
  const pm = { variables: {
    set: (key, value) => values.set(key, value),
    replaceIn: value => value.replace('{{$guid}}', randomUUID()),
  } };
  for (const event of item.event.filter(event => event.listen === 'prerequest')) {
    vm.runInNewContext(event.script.exec.join('\n'), { pm, Date });
  }
  return JSON.parse(item.request.body.raw.replace(/{{([^}]+)}}/g, (_, key) => {
    assert.ok(values.has(key), `Missing variable: ${key}`);
    return values.get(key);
  }));
}
const payload = generate();
assert.equal(payload.rowCounter.projectId, payload.id);
assert.notEqual(payload.rowCounter.id, payload.id);
assert.notEqual(generate().id, payload.id);
const options = { whitelist: true, forbidNonWhitelisted: true };
assert.deepEqual(validateSync(plainToInstance(SaveProjectDto, payload), options), []);
const missingCounter = { ...payload };
delete missingCounter.rowCounter;
assert.ok(validateSync(plainToInstance(SaveProjectDto, missingCounter), options).length > 0);
const oldPayload = { name: 'QA Cardigan', status: 'co', memo: 'Postman smoke project' };
assert.ok(validateSync(plainToInstance(SaveProjectDto, oldPayload), options).length > 0);
console.log('PASS: request generation, UUID relationships, current DTO and invalid controls');
