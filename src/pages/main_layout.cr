abstract class MainLayout
  include Lucky::HTMLPage

  abstract def content
  abstract def page_title

  # The default page title. It is passed to `Shared::LayoutHead`.
  #
  # Add a `page_title` method to pages to override it. You can also remove
  # This method so every page is required to have its own page title.
  def page_title
    "Tavla game for telegram https://t.me/tavla_best_bot?game=tavla"
  end

  def render
    html_doctype

    html lang: "en" do
      mount Shared::LayoutHead, page_title: page_title # , context: context

      body class: "container" do
        # mount Shared::FlashMessages, context.flash
        content
      end
    end
  end
end
