module Jekyll

  module MonthlyArchiveUtil
    def self.archive_base(site)
      site.config['monthly_archive'] && site.config['monthly_archive']['path'] || '/blog'
    end
  end

  # Generator class invoked from Jekyll
  class MonthlyArchiveGenerator < Generator
    def generate(site)
      posts_group_by_year_and_month(site).each do |ym, list|
        site.pages << MonthlyArchivePage.new(site, MonthlyArchiveUtil.archive_base(site),
        ym[0], ym[1], list)
      end
    end

    def posts_group_by_year_and_month(site)
      site.posts.docs.each.group_by { |post| [post.date.year, post.date.month] }
    end

  end

  # Actual page instances
  class MonthlyArchivePage < Page

    ATTRIBUTES_FOR_LIQUID = %w[
      year,
      month,
      date,
      content
    ]

    def initialize(site, dir, year, month, posts)
      @site = site
      @dir = dir
      @year = year
      @month = month
      @archive_dir_name = '%04d/%02d' % [year, month]
      @date = Date.new(@year, @month)
      @layout =  site.config['monthly_archive'] && site.config['monthly_archive']['layout'] || 'monthly_archive'
      self.ext = '.html'
      self.basename = 'index'
      self.content = <<-EOS

      EOS
      self.data = {
        'layout' => @layout,
        'type' => 'archive',
        'title' => "Monthly archive for #{@year}/#{@month}",
        'posts' => posts,
        'url' => File.join('/',
        MonthlyArchiveUtil.archive_base(site),
        @archive_dir_name, 'index.html')
      }
    end

    def render(layouts, site_payload)
      payload = {
        'page' => self.to_liquid,
        'paginator' => pager.to_liquid
      }.merge(site_payload)
      do_layout(payload, layouts)
    end

    def to_liquid(attr = nil)
      self.data.merge({
        'content' => self.content,
        'date' => @date,
        'month' => @month,
        'year' => @year
        })
      end

      def destination(dest)
        File.join('/', dest, @dir, @archive_dir_name, 'index.html')
      end

    end

    class MonthlyArchive < Liquid::Tag
      def initialize(tag_name, markup, tokens)
        @opts = {}
        if markup.strip =~ /\s*counter:(\w+)/i
          @opts['counter'] = ($1 == 'true')
          markup = markup.strip.sub(/counter: *(\w+)/i, '')
        end
        super
      end

      def render(context)
        html = ""
        posts = context.registers[:site].posts.docs.reverse
        posts = posts.group_by{|c| {"month" => c.date.month, "year" => c.date.year}}
        posts.each do |period, post|
          month_dir = '/' + MonthlyArchiveUtil.archive_base(context.registers[:site])
          month_dir << "/#{period["year"]}/#{"%02d" % period["month"]}/"
          html << "<li><a href='#{month_dir}'>#{period["year"]}-#{"%02d" % period["month"]}"
          html << "  (#{post.count})" if @opts['counter']
          html << "</a></li>"
        end
        html
      end
    end
  end

  Liquid::Template.register_tag('tag_monthly_archive', Jekyll::MonthlyArchive)
