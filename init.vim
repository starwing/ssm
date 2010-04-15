" let &rtp = glob($VIMRTDIR).','.&rtp.','.glob($VIMRTDIR).'/after'
let &rtp = glob($VIMRTDIR).','.$VIM.'/vim72'
let $MYVIMRC=$VIM.'/_vimrc'
so $MYVIMRC

set titlestring+=\ [IN\ TEST]
set co=80 lines=24
