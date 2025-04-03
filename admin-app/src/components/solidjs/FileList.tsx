import { deleteFile, getFiles } from '@/core/controllers/archivos'
import { FileCard } from './FileCard'
import { createEffect, createSignal, For, Show } from 'solid-js'
import type { FileEntity } from '@/types/archivos'
import { RefreshIcon } from './icons/RefreshIcon'
import type { DOMElement } from 'solid-js/jsx-runtime'
import { LoadingIcon } from './icons/LoadingIcon'

const [fetchTrigger, setFetchTrigger] = createSignal(0)

export const FetchButton = () => {
  const classList = 'animate-spin'.split(' ')

  const handleClick = (
    e: MouseEvent & {
      currentTarget: HTMLButtonElement
      target: DOMElement
    }
  ) => {
    const $svg = e.target.querySelector('svg')

    if ($svg != null) {
      $svg.classList.add(...classList)
      setTimeout(() => {
        $svg.classList.remove(...classList)
      }, 500)
    }

    setFetchTrigger(fetchTrigger() + 1)
  }

  return (
    <button
      onClick={handleClick}
      class="p-2 rounded text-white/50
        hover:bg-white/5 hover:text-white/70
        active:bg-white/10 active:text-white/80"
    >
      <RefreshIcon class="w-6 h-6 pointer-events-none" />
    </button>
  )
}

export const FileList = () => {
  const [fetched, setFetched] = createSignal<boolean>(false)
  const [files, setFiles] = createSignal<FileEntity[]>([])
  const [error, setError] = createSignal<string>('')

  const fetchData = async () => {
    const { data: apiData, error: apiError } = await getFiles()

    setFetched(true)

    if (apiError != null) {
      setError(apiError.message)
      return
    }

    setError('')
    setFiles(apiData)
  }

  createEffect(() => {
    if (fetchTrigger() >= 0) {
      fetchData()
    }
  })

  const deleteItem = (id: number) => async () => {
    const { error: apiError } = await deleteFile({ id })

    if (apiError != null) {
      setError(apiError.message)
      return
    }

    const newData = files().filter((f) => f.id !== id)
    setFiles(newData)
  }

  return (
    <div class="grow flex flex-col gap-3 px-3 overflow-y-auto scrollbar-thin relative">
      <Show when={error().length > 0}>
        <div class="text-sm text-red-400 font-semibold">{error()}</div>
      </Show>
      <Show when={!fetched()}>
        <div class="flex flex-col justify-center items-center gap-4 h-full text-white/70">
          <LoadingIcon class="w-6 h-6 animate-spin" />
          <p class="text-sm font-semibold">Loading files...</p>
        </div>
      </Show>
      <For each={files()}>
        {(item) => <FileCard file={item} deleteItem={deleteItem(item.id)} />}
      </For>
    </div>
  )
}
