import { deleteFile, getFiles } from '@/core/controllers/archivos'
import { FileCard } from './FileCard'
import { createEffect, createSignal, For, on, Show } from 'solid-js'
import type { FileEntity } from '@/types/archivos'
import { RefreshIcon } from './icons/RefreshIcon'
import { LoadingIcon } from './icons/LoadingIcon'
import { debounce } from '@/core/lib/utils'

const [fetchTrigger, setFetchTrigger] = createSignal(0)

export const FetchButton = () => {
  const [fetching, setFetching] = createSignal(false)

  const debounceSetFetching = debounce(setFetching, 500)

  const refreshData = () => {
    if (fetching()) {
      return
    }
    setFetchTrigger(fetchTrigger() + 1)
    setFetching(true)
    debounceSetFetching(false)
  }

  return (
    <button
      class="p-2 rounded text-white/50 flex items-center gap-1 hover:not-disabled:bg-white/5 hover:not-disabled:text-white/70 active:not-disabled:bg-white/10 active:not-disabled:text-white/80"
      disabled={fetching()}
      onClick={refreshData}
    >
      <Show when={fetching()}>
        <span class="text-sm font-medium">Actualizando...</span>
      </Show>
      <RefreshIcon
        class={`w-6 h-6 pointer-events-none ${fetching() ? 'animate-spin' : ''}`}
      />
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

  createEffect(
    on(fetchTrigger, () => {
      fetchData()
    })
  )

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
