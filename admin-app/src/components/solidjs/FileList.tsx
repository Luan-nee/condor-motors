import { deleteFile, getFiles } from '@/core/controllers/archivos.controller'
import { FileCard } from './FileCard'
import { createEffect, createSignal, onMount } from 'solid-js'
import type { FileEntity } from '@/types/archivos'
import { BubbleLoadingIcon } from './icons/BubbleLoadingIcon'
import { RefreshIcon } from './icons/RefreshIcon'

const [fetchTrigger, setFetchTrigger] = createSignal(0)

export const FetchButton = () => {
  return (
    <button
      onClick={() => {
        setFetchTrigger(fetchTrigger() + 1)
      }}
      class="p-2 rounded text-white/50
        hover:bg-white/5 hover:text-white/70
        active:bg-white/10 active:text-white/80
        hover:[&>svg]:rotate-180"
    >
      <RefreshIcon class="w-6 h-6 transition-transform duration-500" />
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
    <>
      {files().length > 0 &&
        files().map((item) => (
          <FileCard file={item} deleteItem={deleteItem(item.id)} />
        ))}
      {error().length > 0 && (
        <div class="flex flex-col justify-center items-center gap-4 h-full text-white/70">
          <div class="text-sm text-red-400 font-medium">{error()}</div>
        </div>
      )}
      {!fetched() && (
        <div class="flex flex-col justify-center items-center gap-4 h-full text-white/70">
          <BubbleLoadingIcon class="w-8 h-8" />
          <p>Loading files</p>
        </div>
      )}
    </>
  )
}
