#!/usr/bin/env ruby
# frozen_string_literal: true

# Met à jour scripts/tessdata-best-manifest.tsv en téléchargeant la
# dernière version (ou un tag explicite) de tessdata_best, puis régénère
# les formules en appelant generate-tessdata-formulas.rb.
#
# Usage :
#   ruby scripts/update-tessdata-best.rb            # tag = dernier disponible
#   ruby scripts/update-tessdata-best.rb 4.2.0      # tag = 4.2.0
#   ruby scripts/update-tessdata-best.rb --check    # ne fait rien d'autre que
#                                                   # afficher le tag courant
#                                                   # vs amont (exit 0/3)
#
# Pas de dépendance externe : stdlib uniquement.

require "digest"
require "fileutils"
require "json"
require "net/http"
require "uri"

REPO          = "tesseract-ocr/tessdata_best"
SCRIPT_DIR    = __dir__.freeze
MANIFEST      = File.join(SCRIPT_DIR, "tessdata-best-manifest.tsv").freeze
GENERATE      = File.join(SCRIPT_DIR, "generate-tessdata-formulas.rb").freeze
PARALLELISM   = 8

def http_get(url, accept: "application/json")
  uri = URI.parse(url)
  req = Net::HTTP::Get.new(uri)
  req["Accept"] = accept
  req["User-Agent"] = "papilip-homebrew-tap/update-tessdata-best"
  req["Authorization"] = "Bearer #{ENV["GITHUB_TOKEN"]}" if ENV["GITHUB_TOKEN"]
  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                      open_timeout: 15, read_timeout: 60) do |http|
    res = http.request(req)
    raise "HTTP #{res.code} sur #{url}\n#{res.body[0, 500]}" unless res.code.to_i.between?(200, 299)

    res.body
  end
end

def latest_tag
  body = http_get("https://api.github.com/repos/#{REPO}/tags?per_page=1")
  data = JSON.parse(body)
  raise "Aucun tag publié sur #{REPO}" if data.empty?

  data.first["name"]
end

def list_traineddata(tag)
  body = http_get("https://api.github.com/repos/#{REPO}/git/trees/#{tag}?recursive=1")
  tree = JSON.parse(body).fetch("tree")
  tree
    .select { |e| e["type"] == "blob" && e["path"].end_with?(".traineddata") }
    .map { |e| { path: e["path"], size: e["size"].to_i } }
    .sort_by { |e| e[:path] }
end

def stream_sha256(url)
  uri = URI.parse(url)
  digest = Digest::SHA256.new
  size = 0

  follow = lambda do |u|
    Net::HTTP.start(u.host, u.port, use_ssl: u.scheme == "https",
                                    open_timeout: 15, read_timeout: 120) do |http|
      req = Net::HTTP::Get.new(u)
      req["User-Agent"] = "papilip-homebrew-tap/update-tessdata-best"
      http.request(req) do |res|
        case res
        when Net::HTTPRedirection
          return follow.call(URI.parse(res["location"]))
        when Net::HTTPSuccess
          res.read_body do |chunk|
            digest << chunk
            size += chunk.bytesize
          end
        else
          raise "HTTP #{res.code} sur #{u}"
        end
      end
    end
  end

  follow.call(uri)
  [digest.hexdigest, size]
end

def compute_all_shas(tag, files)
  results = Array.new(files.size)
  queue   = Queue.new
  files.each_with_index { |f, i| queue << [i, f] }

  done    = 0
  mutex   = Mutex.new
  threads = Array.new([PARALLELISM, files.size].min) do
    Thread.new do
      until queue.empty?
        i, f = nil
        begin
          i, f = queue.pop(true)
        rescue ThreadError
          break
        end

        url = "https://github.com/#{REPO}/raw/#{tag}/#{f[:path]}"
        sha, size = stream_sha256(url)
        if size != f[:size]
          warn "AVERTISSEMENT: taille différente pour #{f[:path]} (attendu #{f[:size]}, reçu #{size})"
        end
        results[i] = { path: f[:path], size: size, sha256: sha }

        mutex.synchronize do
          done += 1
          warn "[#{done}/#{files.size}] #{f[:path]}"
        end
      end
    end
  end
  threads.each(&:join)
  results
end

def license_sha(tag)
  sha, _size = stream_sha256("https://github.com/#{REPO}/raw/#{tag}/LICENSE")
  sha
end

def current_tag
  return unless File.exist?(MANIFEST)

  File.foreach(MANIFEST) do |line|
    return Regexp.last_match(1) if line =~ /\A#\s*tag=(\S+)/
  end
  nil
end

def write_manifest(tag, l_sha, files)
  File.open(MANIFEST, "w") do |f|
    f.puts "# tag=#{tag}"
    f.puts "# license_sha=#{l_sha}"
    files.each { |e| f.puts "#{e[:path]}\t#{e[:size]}\t#{e[:sha256]}" }
  end
end

# --- Main -------------------------------------------------------------------

mode = :update
target = nil
ARGV.each do |arg|
  case arg
  when "--check" then mode = :check
  when /\A--/    then abort "Option inconnue : #{arg}"
  else                target ||= arg
  end
end

target ||= latest_tag
existing = current_tag

if mode == :check
  puts "manifeste : #{existing || "(aucun)"}"
  puts "amont     : #{target}"
  if existing == target
    puts "à jour"
    exit 0
  else
    puts "MAJ disponible"
    exit 3
  end
end

if existing == target
  puts "Manifeste déjà à jour (tag #{target}). Rien à faire."
  exit 0
end

warn "Tag courant=#{existing.inspect}, cible=#{target}"
warn "Récupération de la liste des fichiers..."
files = list_traineddata(target)
warn "#{files.size} fichiers .traineddata trouvés"

warn "Calcul des SHA256 (#{PARALLELISM} en parallèle, ~1,7 Go à télécharger)..."
shas = compute_all_shas(target, files)
warn "Calcul du SHA du fichier LICENSE..."
l_sha = license_sha(target)

warn "Écriture du manifeste : #{MANIFEST}"
write_manifest(target, l_sha, shas)

warn "Régénération des formules..."
system(RbConfig.ruby, GENERATE) || abort("Échec de la génération")

puts "OK : passé au tag #{target}"
