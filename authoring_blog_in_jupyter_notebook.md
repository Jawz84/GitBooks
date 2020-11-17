---
description: By Jos Koelewijn (@Jawz_84)
---

# I started authoring my blog posts in .NET Interactive \(Jupyter\) Notebooks

I write my blog post in a .NET Interactive \(Jupyter\) Notebook, convert it to MarkDown and upload it to my GitBook blog via GitHub.

## Why

**Reason one**: It really helps me reach flow state.

The Notebook allows me to write in MarkDown, and add PowerShell code _that I can run within the document_. This in itself is a big plus. You can just move your cursor from your content to your example, run it, test someting and move your cursor back to your content, so:

**Reason two**: I am sure _all_ my examples are working and their output is accurate.

It also _captures the output_ of the script/command that I ran within the document. When I am done writing, I restart the notebook kernel running PowerShell \(start a new PowerShell session\) and run all my examples again. This way all code is tested.

## How

Prerequisites for authoring and running a .NET Interactive Notebook

* [VSCode Insiders](https://code.visualstudio.com/insiders/) \*\)
* [.NET 3.1 SDK](https://dotnet.microsoft.com/download/dotnet-core/3.1)
* [VSCode Extension .NET Interactive Notebooks](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.dotnet-interactive-vscode) \(allow it trough your firewall\)

\*\) VSCode non-Insiders could also work, but be advised that it is not supported, and possibly unstable. See what Jon, one of the maintainers says about this when I asked him:

I've noticed that the extension occasionally works in non-Insiders but the notebook APIs aren't stable yet so there's no guarantee it will continue to work. If breaking changes occur in Insiders, they'll be fixed faster.— Jon Sequeira \(@jonsequitur\) [November 16, 2020](https://twitter.com/jonsequitur/status/1328404886917058561?ref_src=twsrc%5Etfw)

### Export to Markdown

If you want to export to Markdown, you will need Python, Jupyter and a Jupyter tool called `nbconvert`. Easiest way to get Python + Jupyter, is to use [Anaconda](https://www.anaconda.com/products/individual). Install it as single user.

After that, open the Anaconda Powershell console and install `nbconvert` with:

```text
# from the Anaconda PowerShell console
conda install nbconvert --yes
```

After install you can now close Anaconda PowerShell console.

Now we can use `nbconvert` with `jupyter` to convert our `.ipynb` to MarkDown.

### Writing a Notebook

In VSCode, press F1 and seach for the command `> .NET interactive: create new blank notebook`. The first time you run this, it will download some more prerequisites automatically in the background.

In a Notebook, you can choose between insterting a MarkDown and Code block. You can also convert between the two, split and merge them etc.

A Code Block will run a certain language. Set it to `PowerShell (.NET Interactive)` if you want to use PowerShell. Use `Ctrl-Alt-Enter` to run a cell.

All your code blocks in the document are connected to the same session, a 'kernel' in Jupyter. You can restart that kernel from the VSCode command menu to get a fresh session: `> .NET Interactive: Restart the current notebook's kernel`.

When you are done writing and testing, you can save your work. When you come back to your work later, you will notice you cannot open a .ipynb file directly in VSCode, it will display the underlying JSON file. To re-open a Notebook, right click the .ipynb file in VSCode and choose `Open with..` from the context menu, and select `.NET Interactive for Jupyter Notebooks` from the drop down menu. You can use the cog to the right of that to select your default way of opening .ipynb files if you like.

### Exporting a Notebook to MarkDown

To export your Notebook including code blocks and their output to MarkDown, use a PowerShell session somewhere and run this:

```text
# you need to tell powershell where `jupyter` is installed, this is one way to do that:
if ($env:Path -notmatch "anaconda3") {
    $env:Path += ";${HOME}\anaconda3\Scripts"
}
# run nbconvert
jupyter nbconvert C:\Users\Jos\Desktop\Untitled-1.ipynb --to markdown
```

The resulting MarkDown file is not super neat. That's why I use a cleanup script with some regex to tidy it up after conversion.

You can find the script I use to clean things up here: [MarkDown cleaner on GitHub](https://github.com/Jawz84/GitBooks/blob/master/Convert-NotebookToMarkdown.ps1). Usually I only have to do some minor tweaks after running that. When I am happy with it, I upload the post to my GitBook blog via GitHub.

I hope you found this useful. Please feel free to reach out to me if you have questions. You can [ping me on Twitter](https://www.twitter.com/Jawz_84), or drop me a message on the PowerShell Discord server.

