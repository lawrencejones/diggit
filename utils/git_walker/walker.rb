require 'git'

module GitWalker
  # Walks a given git repo to produce a recursive structure of each directory and file
  # found from the root, computing a score for each file/directory using the supplied
  # block.
  #
  # Example of...
  #
  #     GitWalker::Walker.
  #       new(repo_path,
  #           metric_lambda: ->(target) { File.size(target) }
  #           file_glob: "**/{*.rb,*.js}")
  #
  # ...would walk the repo at `repo_path`, computing the recursive file size of each
  # file/directory that is tracked by the repo, and that matches the file_glob.
  class Walker
    def initialize(root, metric_lambda: nil, file_glob: nil)
      @root = File.realpath(root)
      @repo = Git.open(root)
      @metric_lambda = metric_lambda
      @file_glob = file_glob || '**/*'

    rescue ArgumentError
      raise "Not valid git repository! #{@root}"
    end

    attr_reader :root, :repo

    def frame
      @frame ||= compute_frame
    end

    private

    def compute_frame
      all_tracked_files.each_with_object(new_frame) do |relative_path, frame|
        score = compute_metric(relative_path)
        next if score == 0

        frame[:score] += score
        get_or_create_frame(frame, relative_path, score).delete(:items)
      end
    end

    def all_tracked_files
      repo.ls_files.keys.
        select { |file| File.fnmatch(@file_glob, file, File::FNM_EXTGLOB) }
    end

    def get_or_create_frame(frame, relative_path, score)
      directories = relative_path.split(File::SEPARATOR)

      directories.reduce(frame) do |frm, directory|
        frm[:items][directory] ||= new_frame(File.join(frm[:path], directory))
        frm[:items][directory].tap { |f| f[:score] += score }
      end
    end

    def new_frame(path = File.basename(root))
      { path: path, items: {}, score: 0 }
    end

    def compute_metric(relative_path)
      @metric_lambda[resolve(relative_path), repo]
    end

    def resolve(relative_path)
      File.join(root, relative_path)
    end

    def format_relative_path(path)
      File.join(File.basename(root), path)
    end
  end
end
