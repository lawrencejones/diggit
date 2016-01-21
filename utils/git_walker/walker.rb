module GitWalker
  # Walks a given git repo to produce a recursive structure of each directory and file
  # found from the root, computing a score for each file/directory using the supplied
  # block.
  #
  # Example of...
  #
  #     GitWalker::Walker.new(repo_path, metric_lambda: ->(target) { File.size(target) })
  #
  # ...would walk the repo at `repo_path`, computing the recursive file size of each
  # file/directory that is tracked by the repo.
  class Walker
    def initialize(root, metric_lambda: nil)
      @root = File.realpath(root)
      verify_root!

      @metric_lambda = metric_lambda
      @frame = compute_frame
    end

    attr_reader :frame, :root

    private

    def verify_root!
      unless git_exec('rev-parse --is-inside-work-tree') == 'true'
        fail "Is not valid git repository! #{@root}"
      end
    end

    def git_exec(cmd)
      `GIT_DIR="#{@root}/.git" git #{cmd}`.chomp
    end

    def all_tracked_files
      git_exec('ls-files').split
    end

    def compute_frame
      all_tracked_files.each_with_object(new_frame) do |file, frame|
        frame_score = compute_metric(file)
        next if frame_score == 0

        frame[:score] += frame_score

        directories = file.split(File::SEPARATOR)
        basename = directories.pop

        sub_frame = directories.reduce(frame) do |frm, dir|
          frm[:items][dir] ||= new_frame(File.join(frm[:path], dir))
          frm[:items][dir].tap { |f| f[:score] += frame_score }
        end

        sub_frame[:items][basename] = {
          path: File.join(File.basename(@root), file),
          score: frame_score,
        }
      end
    end

    def new_frame(path = File.basename(@root))
      { path: path, items: {}, score: 0 }
    end

    def compute_metric(target)
      @metric_lambda[File.join(@root, target)]
    end
  end
end
