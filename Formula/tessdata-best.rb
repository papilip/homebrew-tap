# frozen_string_literal: true

class TessdataBest < Formula
  desc "Wrapper that runs Tesseract OCR with tessdata_best models"
  homepage "https://github.com/tesseract-ocr/tessdata_best"
  url "https://github.com/tesseract-ocr/tessdata_best/raw/4.1.0/LICENSE"
  sha256 "a6cba85bc92e0cff7a450b1d873c0eaa2e9fc96bf472df0247a26bec77bf3ff9"
  license "Apache-2.0"

  depends_on "tesseract"

  def install
    pkgshare.install "LICENSE"

    data_dir = "#{HOMEBREW_PREFIX}/share/tessdata_best"
    tesseract_bin = Formula["tesseract"].opt_bin/"tesseract"

    (bin/"tesseract-best").write <<~SH
      #!/bin/sh
      # Lance Tesseract avec TESSDATA_PREFIX positionné sur tessdata_best.
      # Une valeur déjà exportée par l'utilisateur a la priorité.
      export TESSDATA_PREFIX="${TESSDATA_PREFIX:-#{data_dir}}"
      exec "#{tesseract_bin}" "$@"
    SH
    (bin/"tesseract-best").chmod(0755)

    (share/"tessdata-best").mkpath
    (share/"tessdata-best/env.sh").write <<~SH
      # Sourcez ce fichier depuis votre shell pour utiliser tessdata_best
      # avec la commande `tesseract` standard :
      #
      #   echo 'source #{HOMEBREW_PREFIX}/share/tessdata-best/env.sh' >> ~/.zshrc
      #
      # Vous pouvez ensuite surcharger la variable manuellement à tout moment.
      export TESSDATA_PREFIX="#{data_dir}"
    SH
  end

  def caveats
    <<~EOS
      Deux moyens d'utiliser tessdata_best au lieu de tessdata :

      1) Wrapper dédié (laisse `tesseract` intact pour tessdata_fast) :
           tesseract-best image.png out -l fra

      2) Variable d'environnement (impacte aussi `tesseract`) :
           export TESSDATA_PREFIX="#{HOMEBREW_PREFIX}/share/tessdata_best"
         ou, persistant :
           echo 'source #{HOMEBREW_PREFIX}/share/tessdata-best/env.sh' >> ~/.zshrc

      Pensez à installer au moins une langue, par exemple :
           brew install papilip/tap/tessdata-best-{osd,fra,eng}
    EOS
  end

  test do
    assert_path_exists bin/"tesseract-best"
    assert_path_exists share/"tessdata-best/env.sh"

    # Le wrapper doit transmettre les arguments à tesseract.
    assert_match(/tesseract/, shell_output("#{bin}/tesseract-best --version 2>&1"))

    # Et il doit pointer vers le bon TESSDATA_PREFIX par défaut.
    expected = "#{HOMEBREW_PREFIX}/share/tessdata_best"
    script = (bin/"tesseract-best").read
    assert_match(/TESSDATA_PREFIX.*#{Regexp.escape(expected)}/, script)
  end
end
