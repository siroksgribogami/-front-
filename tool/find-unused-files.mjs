import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const libRoot = path.join(projectRoot, 'lib')
const resourceRoots = ['assets', 'picture', 'fonts', 'svg icons', 'web']
const sourceExtensions = new Set(['.dart', '.ts', '.tsx', '.js', '.jsx', '.css'])
const resourceExtensions = new Set([
  '.avif',
  '.glb',
  '.gif',
  '.html',
  '.jpeg',
  '.jpg',
  '.json',
  '.otf',
  '.png',
  '.svg',
  '.ttf',
  '.wasm',
  '.webp',
])

function walk(directory) {
  if (!fs.existsSync(directory)) return []
  const files = []

  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const entryPath = path.join(directory, entry.name)
    if (entry.isDirectory()) files.push(...walk(entryPath))
    else files.push(entryPath)
  }

  return files
}

function read(filePath) {
  return fs.readFileSync(filePath, 'utf8')
}

function normalize(filePath) {
  return path.normalize(filePath).toLowerCase()
}

function resolveDartImport(importer, specifier) {
  let importPath
  if (specifier.startsWith('package:art_front/')) {
    importPath = path.join(projectRoot, specifier.slice('package:art_front/'.length))
  } else if (specifier.startsWith('.')) {
    importPath = path.resolve(path.dirname(importer), specifier)
  } else if (!specifier.startsWith('dart:') && !specifier.startsWith('package:')) {
    const importerDirectory = path.dirname(importer)
    importPath = path.join(importerDirectory === libRoot ? libRoot : importerDirectory, specifier)
  } else {
    return null
  }

  if (!path.extname(importPath)) importPath += '.dart'
  return fs.existsSync(importPath) ? importPath : null
}

function extractDartDependencies(content) {
  const dependencies = []
  const directivePattern = /(?:import|export|part)\s+([^;]+);/g
  for (const directive of content.matchAll(directivePattern)) {
    for (const match of directive[1].matchAll(/['"]([^'"]+)['"]/g)) dependencies.push(match[1])
  }
  return dependencies
}

function collectReachableDartFiles(dartFiles) {
  const dartByPath = new Map(dartFiles.map((filePath) => [normalize(filePath), filePath]))
  const reachable = new Set()
  const pending = [path.join(libRoot, 'main.dart')]

  while (pending.length) {
    const current = pending.pop()
    if (!current || reachable.has(normalize(current))) continue
    reachable.add(normalize(current))

    for (const specifier of extractDartDependencies(read(current))) {
      const resolved = resolveDartImport(current, specifier)
      if (resolved && dartByPath.has(normalize(resolved))) pending.push(resolved)
    }
  }

  return new Set([...reachable].map((filePath) => dartByPath.get(filePath) || filePath))
}

function getSearchableFiles(allFiles) {
  return allFiles.filter((filePath) => {
    const relativePath = path.relative(projectRoot, filePath)
    return !relativePath.split(path.sep).includes('build')
  })
}

function isResourceReferenced(resourcePath, searchableFiles) {
  const relativePath = path.relative(projectRoot, resourcePath).split(path.sep).join('/')
  const basename = path.basename(resourcePath)
  const references = [relativePath, `/${relativePath}`, basename]

  return searchableFiles.some((filePath) => {
    if (normalize(filePath) === normalize(resourcePath)) return false
    const content = read(filePath)
    return references.some((reference) => content.includes(reference))
  })
}

function printSection(title, files) {
  console.log(`\n${title} (${files.length})`)
  if (!files.length) {
    console.log('  none')
    return
  }
  for (const filePath of files.sort()) console.log(`  ${path.relative(projectRoot, filePath)}`)
}

const allFiles = walk(projectRoot)
const dartFiles = allFiles.filter((filePath) => path.extname(filePath).toLowerCase() === '.dart' && filePath.includes(`${path.sep}lib${path.sep}`))
const resourceFiles = resourceRoots.flatMap((root) => walk(path.join(projectRoot, root))).filter((filePath) => resourceExtensions.has(path.extname(filePath).toLowerCase()))
const reachableDartFiles = collectReachableDartFiles(dartFiles)
const unusedDartFiles = dartFiles.filter((filePath) => !reachableDartFiles.has(filePath))
const searchableFiles = getSearchableFiles(allFiles)
const unreferencedResources = resourceFiles.filter((filePath) => !isResourceReferenced(filePath, searchableFiles))

console.log('Dead-code and resource audit: main Flutter project')
console.log('Entrypoint: lib/main.dart')
printSection('Unreachable Dart files', unusedDartFiles)
printSection('Unreferenced resources', unreferencedResources)
console.log('\nNo files were deleted.')